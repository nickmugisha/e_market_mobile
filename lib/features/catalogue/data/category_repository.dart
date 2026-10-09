import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../domain/market_category.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestoreCollections.categories);

  Stream<List<MarketCategory>> watchActiveCategories() {
    return _categories.where('active', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final categories = snapshot.docs
          .map((doc) => MarketCategory.fromMap(doc.id, doc.data()))
          .toList();
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    });
  }

  Future<void> seedDefaults({required String sellerId}) async {
    const defaults = <String, ({String name, String description})>{
      'fashion': (
        name: 'Fashion',
        description: 'Clothing, shoes and accessories.',
      ),
      'electronics': (
        name: 'Electronics',
        description: 'Phones, devices and electronic accessories.',
      ),
      'beauty': (
        name: 'Beauty',
        description: 'Beauty and personal care products.',
      ),
      'home': (
        name: 'Home',
        description: 'Home essentials and everyday living products.',
      ),
      'other': (
        name: 'Other',
        description: 'Products that do not fit another category.',
      ),
    };

    for (final entry in defaults.entries) {
      final ref = _categories.doc(entry.key);
      final existing = await ref.get();
      if (existing.exists) continue;

      await ref.set({
        'name': entry.value.name,
        'description': entry.value.description,
        'active': true,
        'createdBy': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
