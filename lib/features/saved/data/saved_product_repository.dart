import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';

class SavedProductRepository {
  SavedProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String clientUid) {
    return _firestore
        .collection(FirestoreCollections.saved)
        .doc(clientUid)
        .collection(FirestoreSubcollections.items);
  }

  Stream<Set<String>> watchSavedIds(String clientUid) {
    return _items(
      clientUid,
    ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<bool> watchSaved({
    required String clientUid,
    required String productId,
  }) {
    return _items(
      clientUid,
    ).doc(productId).snapshots().map((snapshot) => snapshot.exists);
  }

  Future<void> save({required String clientUid, required String productId}) {
    return _items(clientUid).doc(productId).set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove({required String clientUid, required String productId}) {
    return _items(clientUid).doc(productId).delete();
  }

  Future<void> toggle({
    required String clientUid,
    required String productId,
    required bool currentlySaved,
  }) {
    if (currentlySaved) {
      return remove(clientUid: clientUid, productId: productId);
    }

    return save(clientUid: clientUid, productId: productId);
  }
}
