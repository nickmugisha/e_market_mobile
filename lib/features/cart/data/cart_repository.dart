import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../catalogue/domain/product.dart';
import '../domain/cart_item.dart';

class CartFailure implements Exception {
  const CartFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class CartRepository {
  CartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _cart(String clientUid) {
    return _firestore
        .collection(FirestoreCollections.carts)
        .doc(clientUid);
  }

  CollectionReference<Map<String, dynamic>> _items(String clientUid) {
    return _cart(clientUid).collection(FirestoreSubcollections.items);
  }

  DocumentReference<Map<String, dynamic>> _product(String productId) {
    return _firestore
        .collection(FirestoreCollections.products)
        .doc(productId);
  }

  Stream<List<CartItem>> watchItems(String clientUid) {
    return _items(clientUid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();

      items.sort((a, b) {
        final aDate = a.updatedAt ??
            a.addedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ??
            b.addedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  Future<List<CartItem>> fetchItemsFromServer(String clientUid) async {
    final snapshot =
        await _items(clientUid).get(const GetOptions(source: Source.server));

    final items = snapshot.docs
        .map((doc) => CartItem.fromMap(doc.id, doc.data()))
        .toList();

    items.sort((a, b) {
      final aDate =
          a.updatedAt ?? a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.updatedAt ?? b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return items;
  }

  Future<void> addProduct({
    required String clientUid,
    required String productId,
    int quantity = 1,
  }) async {
    if (quantity <= 0) {
      throw const CartFailure('Quantity must be at least 1.');
    }

    final cartRef = _cart(clientUid);
    final itemRef = _items(clientUid).doc(productId);
    final productRef = _product(productId);

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final productData = productSnapshot.data();

      if (!productSnapshot.exists || productData == null) {
        throw const CartFailure('This product no longer exists.');
      }

      final product = Product.fromMap(productSnapshot.id, productData);
      if (!product.active) {
        throw const CartFailure('This product is currently unavailable.');
      }
      if (product.stock <= 0) {
        throw const CartFailure('This product is out of stock.');
      }

      final cartSnapshot = await transaction.get(cartRef);
      final cartData = cartSnapshot.data();

      if (cartSnapshot.exists &&
          cartData != null &&
          cartData['sellerId'] != product.sellerId) {
        throw const CartFailure(
          'Your cart already contains products from another seller. '
          'Clear that cart before adding this product.',
        );
      }

      final itemSnapshot = await transaction.get(itemRef);
      final existingData = itemSnapshot.data();
      final rawQuantity = existingData?['quantity'];
      final existingQuantity = rawQuantity is int ? rawQuantity : 0;
      final nextQuantity = existingQuantity + quantity;

      if (nextQuantity > product.stock) {
        throw CartFailure(
          'Only ${product.stock} item${product.stock == 1 ? '' : 's'} '
          'are available.',
        );
      }

      if (cartSnapshot.exists) {
        transaction.update(cartRef, {
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(cartRef, {
          'clientId': clientUid,
          'sellerId': product.sellerId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final itemData = <String, dynamic>{
        'productId': product.id,
        'sellerId': product.sellerId,
        'productName': product.name,
        'imageRef': product.imageRef,
        'quantity': nextQuantity,
        'unitPrice': product.price,
        'currency': product.currency.code,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (itemSnapshot.exists) {
        transaction.update(itemRef, itemData);
      } else {
        transaction.set(itemRef, {
          ...itemData,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> setQuantity({
    required String clientUid,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(
        clientUid: clientUid,
        productId: productId,
      );
      return;
    }

    final cartRef = _cart(clientUid);
    final itemRef = _items(clientUid).doc(productId);
    final productRef = _product(productId);

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final productData = productSnapshot.data();

      if (!productSnapshot.exists || productData == null) {
        throw const CartFailure('This product no longer exists.');
      }

      final product = Product.fromMap(productSnapshot.id, productData);
      if (!product.active) {
        throw const CartFailure('This product is currently unavailable.');
      }
      if (quantity > product.stock) {
        throw CartFailure(
          'Only ${product.stock} item${product.stock == 1 ? '' : 's'} '
          'are available.',
        );
      }

      final cartSnapshot = await transaction.get(cartRef);
      final cartData = cartSnapshot.data();

      if (!cartSnapshot.exists || cartData == null) {
        throw const CartFailure('Your cart is no longer available.');
      }

      if (cartData['sellerId'] != product.sellerId) {
        throw const CartFailure('The cart seller no longer matches this product.');
      }

      final itemSnapshot = await transaction.get(itemRef);
      if (!itemSnapshot.exists) {
        throw const CartFailure('This item is no longer in your cart.');
      }

      transaction.update(cartRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(itemRef, {
        'sellerId': product.sellerId,
        'productName': product.name,
        'imageRef': product.imageRef,
        'quantity': quantity,
        'unitPrice': product.price,
        'currency': product.currency.code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeItem({
    required String clientUid,
    required String productId,
  }) async {
    await _items(clientUid).doc(productId).delete();
    await _deleteCartDocumentIfEmpty(clientUid);
  }

  Future<void> clear(String clientUid) async {
    final snapshot = await _items(clientUid).get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_cart(clientUid));
    await batch.commit();
  }

  Future<void> _deleteCartDocumentIfEmpty(String clientUid) async {
    final remaining = await _items(clientUid).limit(1).get();
    if (remaining.docs.isEmpty) {
      await _cart(clientUid).delete();
    }
  }
}
