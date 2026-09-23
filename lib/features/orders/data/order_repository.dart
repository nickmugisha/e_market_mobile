import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../domain/order_models.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  Stream<List<MarketOrder>> watchClientOrders(String clientId) {
    return _orders.where('clientId', isEqualTo: clientId).snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => MarketOrder.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort(_newestFirst);
      return orders;
    });
  }

  Stream<List<MarketOrder>> watchSellerOrders(String sellerId) {
    return _orders.where('sellerId', isEqualTo: sellerId).snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => MarketOrder.fromMap(doc.id, doc.data()))
          .toList();
      orders.sort(_newestFirst);
      return orders;
    });
  }

  Stream<List<OrderItem>> watchOrderItems(String orderId) {
    return _orders
        .doc(orderId)
        .collection(FirestoreSubcollections.items)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderItem.fromMap(doc.id, doc.data()))
            .toList(growable: false));
  }

  Future<String> createOrder({
    required String clientId,
    required String sellerId,
    required String clientName,
    required String clientPhone,
    required FulfillmentType fulfillmentType,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    required String deliveryAddress,
    required List<OrderLineDraft> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('An order must contain at least one item.');
    }

    final currency = items.first.currency;
    for (final item in items) {
      if (item.sellerId != sellerId) {
        throw ArgumentError('All items in an order must belong to one seller.');
      }
      if (item.currency != currency) {
        throw ArgumentError('All items in an order must use one currency.');
      }
      if (item.quantity <= 0 || item.unitPrice < 0) {
        throw ArgumentError('Order quantities and prices must be valid.');
      }
    }

    final total = items.fold<double>(0, (runningTotal, item) => runningTotal + item.subtotal);
    final orderRef = _orders.doc();
    final batch = _firestore.batch();

    batch.set(orderRef, {
      'clientId': clientId,
      'sellerId': sellerId,
      'clientName': clientName.trim(),
      'clientPhone': clientPhone.trim(),
      'status': OrderStatus.pending.name,
      'fulfillmentType': fulfillmentType.name,
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus.name,
      'currency': currency.code,
      'total': total,
      'deliveryAddress': deliveryAddress.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final item in items) {
      final itemRef = orderRef.collection(FirestoreSubcollections.items).doc();
      batch.set(itemRef, {
        'productId': item.productId,
        'sellerId': item.sellerId,
        'productName': item.productName,
        'imageRef': item.imageRef,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'subtotal': item.subtotal,
        'currency': item.currency.code,
      });
    }

    await batch.commit();
    return orderRef.id;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _newestFirst(MarketOrder a, MarketOrder b) {
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
