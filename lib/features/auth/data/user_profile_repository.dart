import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../domain/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> updateProfile({
    required UserProfile profile,
    required String name,
    required String phone,
    required String whatsappNumber,
  }) async {
    final cleanedName = name.trim();
    final cleanedPhone = phone.trim();
    final cleanedWhatsapp = profile.role == UserRole.seller
        ? whatsappNumber.trim()
        : '';

    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(profile.uid);

    if (profile.role != UserRole.seller) {
      await userRef.update({
        'name': cleanedName,
        'phone': cleanedPhone,
        'whatsappNumber': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final products = await _firestore
        .collection(FirestoreCollections.products)
        .where('sellerId', isEqualTo: profile.uid)
        .get(const GetOptions(source: Source.server));

    if (products.docs.length > 450) {
      throw StateError(
        'This seller has too many products for one profile-sync batch.',
      );
    }

    final batch = _firestore.batch();

    batch.update(userRef, {
      'name': cleanedName,
      'phone': cleanedPhone,
      'whatsappNumber': cleanedWhatsapp,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final product in products.docs) {
      batch.update(product.reference, {
        'sellerName': cleanedName,
        'sellerWhatsapp': cleanedWhatsapp,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromMap(data);
    });
  }
}
