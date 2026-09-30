import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_collections.dart';
import '../domain/product.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  Stream<List<Product>> watchActiveProducts() {
    return _products.where('active', isEqualTo: true).snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      products.sort(_newestFirst);
      return products;
    });
  }

  Stream<List<Product>> watchSellerProducts(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      products.sort(_newestFirst);
      return products;
    });
  }

  Stream<Product?> watchProduct(String productId) {
    return _products.doc(productId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return Product.fromMap(snapshot.id, data);
    });
  }

  Future<List<Product>> fetchActiveProductsFromServer() async {
    final snapshot = await _products
        .where('active', isEqualTo: true)
        .get(const GetOptions(source: Source.server));

    final products = snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList();
    products.sort(_newestFirst);
    return products;
  }

  Future<String> createProduct({
    required String sellerId,
    required String sellerName,
    required String sellerWhatsapp,
    required String name,
    required String description,
    required String categoryId,
    required String categoryName,
    required double price,
    required MarketCurrency currency,
    required int stock,
    required String imageRef,
    bool active = true,
  }) async {
    final ref = _products.doc();
    await ref.set({
      'sellerId': sellerId,
      'sellerName': sellerName.trim(),
      'sellerWhatsapp': sellerWhatsapp.trim(),
      'name': name.trim(),
      'description': description.trim(),
      'categoryId': categoryId,
      'categoryName': categoryName.trim(),
      'price': price,
      'currency': currency.code,
      'stock': stock,
      'imageRef': imageRef.trim(),
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateProduct(Product product) {
    return _products.doc(product.id).update({
      'sellerName': product.sellerName.trim(),
      'sellerWhatsapp': product.sellerWhatsapp.trim(),
      'name': product.name.trim(),
      'description': product.description.trim(),
      'categoryId': product.categoryId,
      'categoryName': product.categoryName.trim(),
      'price': product.price,
      'currency': product.currency.code,
      'stock': product.stock,
      'imageRef': product.imageRef.trim(),
      'active': product.active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStock(String productId, int stock) {
    return _products.doc(productId).update({
      'stock': stock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String productId, bool active) {
    return _products.doc(productId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) =>
      _products.doc(productId).delete();

  int _newestFirst(Product a, Product b) {
    final aDate =
        a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
