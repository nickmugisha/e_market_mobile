import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/currency/currency_service.dart';
import '../../../core/firestore/firestore_collections.dart';
import '../../cart/domain/cart_item.dart';
import '../../catalogue/domain/product.dart';
import '../../checkout/domain/checkout_draft.dart';
import '../domain/order_models.dart';
import '../domain/order_policy.dart';

class OrderFailure implements Exception {
  const OrderFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final CurrencyService _currencyService = const CurrencyService();

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  DocumentReference<Map<String, dynamic>> _cart(String clientId) {
    return _firestore.collection(FirestoreCollections.carts).doc(clientId);
  }

  CollectionReference<Map<String, dynamic>> _cartItems(String clientId) {
    return _cart(clientId).collection(FirestoreSubcollections.items);
  }

  Stream<List<MarketOrder>> watchClientOrders(String clientId) {
    return _orders.where('clientId', isEqualTo: clientId).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map((doc) => MarketOrder.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort(_newestFirst);
      return orders;
    });
  }

  Stream<List<MarketOrder>> watchSellerOrders(String sellerId) {
    return _orders.where('sellerId', isEqualTo: sellerId).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map((doc) => MarketOrder.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort(_newestFirst);
      return orders;
    });
  }

  Stream<MarketOrder?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return MarketOrder.fromMap(snapshot.id, data);
    });
  }

  Stream<List<OrderItem>> watchOrderItems(String orderId) {
    return _orders
        .doc(orderId)
        .collection(FirestoreSubcollections.items)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => OrderItem.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => a.productName.compareTo(b.productName));
          return items;
        });
  }

  Future<String> placeOrder({
    required CheckoutDraft draft,
    required String paymentReference,
  }) async {
    if (draft.items.isEmpty) {
      throw const OrderFailure('Your cart is empty.');
    }
    if (paymentReference.trim().isEmpty) {
      throw const OrderFailure('Payment simulation reference is missing.');
    }

    final orderRef = _orders.doc();
    final cartRef = _cart(draft.clientId);

    await _firestore.runTransaction((transaction) async {
      final cartSnapshot = await transaction.get(cartRef);
      final cartData = cartSnapshot.data();

      if (!cartSnapshot.exists || cartData == null) {
        throw const OrderFailure(
          'Your cart changed. Return to the cart and review it.',
        );
      }

      if (cartData['clientId'] != draft.clientId ||
          cartData['sellerId'] != draft.sellerId) {
        throw const OrderFailure(
          'The current cart no longer matches this checkout.',
        );
      }

      final liveItems = <CartItem>[];
      final liveProducts = <String, Product>{};

      for (final draftItem in draft.items) {
        final cartItemRef = _cartItems(draft.clientId).doc(draftItem.productId);
        final productRef = _products.doc(draftItem.productId);

        final cartItemSnapshot = await transaction.get(cartItemRef);
        final productSnapshot = await transaction.get(productRef);

        final cartItemData = cartItemSnapshot.data();
        final productData = productSnapshot.data();

        if (!cartItemSnapshot.exists || cartItemData == null) {
          throw OrderFailure(
            '${draftItem.productName} is no longer in your cart.',
          );
        }
        if (!productSnapshot.exists || productData == null) {
          throw OrderFailure(
            '${draftItem.productName} is no longer available.',
          );
        }

        final cartItem = CartItem.fromMap(cartItemSnapshot.id, cartItemData);
        final product = Product.fromMap(productSnapshot.id, productData);

        if (cartItem.sellerId != draft.sellerId ||
            product.sellerId != draft.sellerId) {
          throw const OrderFailure(
            'Checkout can only contain products from one seller.',
          );
        }
        if (!product.active) {
          throw OrderFailure('${product.name} is no longer available.');
        }
        if (cartItem.quantity > product.stock) {
          throw OrderFailure(
            '${product.name} only has ${product.stock} '
            'item${product.stock == 1 ? '' : 's'} left.',
          );
        }

        liveItems.add(
          CartItem(
            productId: product.id,
            sellerId: product.sellerId,
            productName: product.name,
            imageRef: product.imageRef,
            quantity: cartItem.quantity,
            unitPrice: product.price,
            currency: product.currency,
            addedAt: cartItem.addedAt,
            updatedAt: cartItem.updatedAt,
          ),
        );
        liveProducts[product.id] = product;
      }

      final displaySubtotal = OrderPolicy.displaySubtotal(
        items: liveItems,
        displayCurrency: draft.displayCurrency,
        currencyService: _currencyService,
      );

      final deliveryFee = OrderPolicy.deliveryFee(
        fulfillmentType: draft.fulfillmentType,
        displayCurrency: draft.displayCurrency,
        currencyService: _currencyService,
      );

      final displayTotal = displaySubtotal + deliveryFee;

      transaction.set(orderRef, {
        'clientId': draft.clientId,
        'sellerId': draft.sellerId,
        'clientName': draft.clientName,
        'clientPhone': draft.clientPhone,
        'status': OrderStatus.pending.name,
        'fulfillmentType': draft.fulfillmentType.name,
        'paymentMethod': draft.paymentMethod.value,
        'paymentStatus': draft.paymentStatus.name,
        'paymentReference': paymentReference.trim(),
        'currency': draft.displayCurrency.code,
        'subtotal': displaySubtotal,
        'deliveryFee': deliveryFee,
        'total': displayTotal,
        'itemCount': liveItems.length,
        'deliveryAddress': draft.deliveryAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final item in liveItems) {
        final product = liveProducts[item.productId]!;
        final orderItemRef = orderRef
            .collection(FirestoreSubcollections.items)
            .doc(item.productId);

        transaction.set(orderItemRef, {
          'productId': product.id,
          'sellerId': product.sellerId,
          'productName': product.name,
          'imageRef': product.imageRef,
          'quantity': item.quantity,
          'unitPrice': product.price,
          'subtotal': product.price * item.quantity,
          'currency': product.currency.code,
        });

        transaction.delete(_cartItems(draft.clientId).doc(item.productId));
      }

      transaction.delete(cartRef);
    });

    return orderRef.id;
  }

  Future<void> sellerTransition({
    required String orderId,
    required String sellerId,
    required OrderStatus targetStatus,
  }) async {
    final orderRef = _orders.doc(orderId);

    final itemSnapshot = await orderRef
        .collection(FirestoreSubcollections.items)
        .get(const GetOptions(source: Source.server));

    final items = itemSnapshot.docs
        .map((doc) => OrderItem.fromMap(doc.id, doc.data()))
        .toList();

    if (items.isEmpty) {
      throw const OrderFailure('This order has no items.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();

      if (!orderSnapshot.exists || orderData == null) {
        throw const OrderFailure('This order no longer exists.');
      }

      final order = MarketOrder.fromMap(orderSnapshot.id, orderData);

      if (order.sellerId != sellerId) {
        throw const OrderFailure('This order belongs to another seller.');
      }

      if (!OrderPolicy.canTransition(order.status, targetStatus)) {
        throw OrderFailure(
          'Cannot move an order from ${order.status.label} '
          'to ${targetStatus.label}.',
        );
      }

      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};

      if (OrderPolicy.shouldReserveStock(order.status, targetStatus) ||
          OrderPolicy.shouldRestoreStock(order.status, targetStatus)) {
        for (final item in items) {
          final productRef = _products.doc(item.productId);
          final productSnapshot = await transaction.get(productRef);
          productSnapshots[item.productId] = productSnapshot;
        }
      }

      if (OrderPolicy.shouldReserveStock(order.status, targetStatus)) {
        for (final item in items) {
          final snapshot = productSnapshots[item.productId]!;
          final data = snapshot.data();

          if (!snapshot.exists || data == null) {
            throw OrderFailure('${item.productName} no longer exists.');
          }

          final product = Product.fromMap(snapshot.id, data);
          if (product.sellerId != sellerId) {
            throw const OrderFailure(
              'One order item no longer belongs to this seller.',
            );
          }
          if (product.stock < item.quantity) {
            throw OrderFailure(
              '${product.name} only has ${product.stock} '
              'item${product.stock == 1 ? '' : 's'} left.',
            );
          }

          transaction.update(_products.doc(product.id), {
            'stock': product.stock - item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (OrderPolicy.shouldRestoreStock(order.status, targetStatus)) {
        for (final item in items) {
          final snapshot = productSnapshots[item.productId]!;
          final data = snapshot.data();

          if (!snapshot.exists || data == null) {
            throw OrderFailure(
              '${item.productName} no longer exists, so its stock '
              'cannot be restored automatically.',
            );
          }

          final product = Product.fromMap(snapshot.id, data);
          if (product.sellerId != sellerId) {
            throw const OrderFailure(
              'One order item no longer belongs to this seller.',
            );
          }

          transaction.update(_products.doc(product.id), {
            'stock': product.stock + item.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final update = <String, dynamic>{
        'status': targetStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (targetStatus == OrderStatus.completed &&
          order.paymentMethod == PaymentMethod.cash &&
          order.paymentStatus == PaymentStatus.pending) {
        update['paymentStatus'] = PaymentStatus.paid.name;
      }

      transaction.update(orderRef, update);
    });
  }

  int _newestFirst(MarketOrder a, MarketOrder b) {
    final aDate =
        a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
