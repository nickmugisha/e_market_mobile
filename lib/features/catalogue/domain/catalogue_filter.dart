import 'product.dart';

abstract final class CatalogueFilter {
  static List<Product> apply({
    required List<Product> products,
    String query = '',
    String? categoryId,
    bool inStockOnly = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return products.where((product) {
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          product.categoryId != categoryId) {
        return false;
      }

      if (inStockOnly && product.stock <= 0) {
        return false;
      }

      if (normalizedQuery.isEmpty) return true;

      final searchable = [
        product.name,
        product.description,
        product.categoryName,
        product.displaySellerName,
      ].join(' ').toLowerCase();

      return searchable.contains(normalizedQuery);
    }).toList();
  }
}
