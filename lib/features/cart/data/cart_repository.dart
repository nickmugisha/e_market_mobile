import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../../catalogue/domain/product.dart';
import '../domain/cart_item.dart';

class CartRepository {
  CartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String clientUid) {
    return _firestore
        .collection(FirestoreCollections.carts)
        .doc(clientUid)
        .collection(FirestoreSubcollections.items);
  }

  Stream<List<CartItem>> watchItems(String clientUid) {
    return _items(clientUid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CartItem.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) {
        final aDate = a.updatedAt ?? a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Future<void> upsertProduct({
    required String clientUid,
    required Product product,
    required int quantity,
  }) async {
    final ref = _items(clientUid).doc(product.id);

    if (quantity <= 0) {
      await ref.delete();
      return;
    }

    final existing = await ref.get();
    final data = <String, dynamic>{
      'productId': product.id,
      'sellerId': product.sellerId,
      'productName': product.name,
      'imageRef': product.imageRef,
      'quantity': quantity,
      'unitPrice': product.price,
      'currency': product.currency.code,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existing.exists) {
      await ref.update(data);
    } else {
      await ref.set({
        ...data,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeItem({
    required String clientUid,
    required String productId,
  }) {
    return _items(clientUid).doc(productId).delete();
  }

  Future<void> clear(String clientUid) async {
    final snapshot = await _items(clientUid).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
