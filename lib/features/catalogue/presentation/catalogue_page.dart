import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_page.dart';
import '../data/category_repository.dart';
import '../data/product_repository.dart';
import '../domain/catalogue_filter.dart';
import '../domain/market_category.dart';
import '../domain/product.dart';
import 'product_detail_page.dart';
import 'widgets/catalogue_product_card.dart';

class CataloguePage extends StatefulWidget {
  const CataloguePage({
    super.key,
    this.profile,
    this.initialCategoryId,
  });

  final UserProfile? profile;
  final String? initialCategoryId;

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final _products = ProductRepository();
  final _categories = CategoryRepository();
  final _search = TextEditingController();

  String? _selectedCategoryId;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await Navigator.of(context).push(
      smoothRoute(
        const AuthPage(
          returnOnSuccess: true,
          showVisitorOption: false,
        ),
      ),
    );
  }

  Future<void> _openProduct(Product product) {
    return Navigator.of(context).push(
      smoothRoute(
        ProductDetailPage(
          productId: product.id,
          initialProduct: product,
          profile: widget.profile,
          onSignInRequested: _signIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            onPressed: () {
              _search.clear();
              setState(() {
                _selectedCategoryId = null;
                _inStockOnly = false;
              });
            },
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<MarketCategory>>(
        stream: _categories.watchActiveCategories(),
        builder: (context, categorySnapshot) {
          final categories =
              categorySnapshot.data ?? const <MarketCategory>[];

          return StreamBuilder<List<Product>>(
            stream: _products.watchActiveProducts(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting &&
                  !productSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productSnapshot.hasError) {
                return const _CatalogueError();
              }

              final allProducts =
                  productSnapshot.data ?? const <Product>[];
              final visibleProducts = CatalogueFilter.apply(
                products: allProducts,
                query: _search.text,
                categoryId: _selectedCategoryId,
                inStockOnly: _inStockOnly,
              );

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  const Text(
                    'Find your next item',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Search the live e-market catalogue by product, category or seller.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _selectedCategoryId == null,
                          onTap: () =>
                              setState(() => _selectedCategoryId = null),
                        ),
                        for (final category in categories) ...[
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: category.name,
                            selected: _selectedCategoryId == category.id,
                            onTap: () => setState(
                              () => _selectedCategoryId = category.id,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        selected: _inStockOnly,
                        label: const Text('In stock only'),
                        avatar: const Icon(
                          Icons.inventory_2_outlined,
                          size: 17,
                        ),
                        onSelected: (value) =>
                            setState(() => _inStockOnly = value),
                      ),
                      const Spacer(),
                      Text(
                        '${visibleProducts.length} result${visibleProducts.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (visibleProducts.isEmpty)
                    const _EmptyCatalogue()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 720 ? 3 : 2;
                        final aspectRatio =
                            constraints.maxWidth >= 720 ? 0.78 : 0.67;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleProducts.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: aspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final product = visibleProducts[index];
                            return CatalogueProductCard(
                              product: product,
                              onTap: () => _openProduct(product),
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.ink,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.muted,
        fontWeight: FontWeight.w800,
      ),
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 50,
            color: AppColors.accent,
          ),
          SizedBox(height: 12),
          Text(
            'No matching products',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search, category or remove the in-stock filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogueError extends StatelessWidget {
  const _CatalogueError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 50,
              color: AppColors.accent,
            ),
            SizedBox(height: 12),
            Text(
              'Catalogue unavailable',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Check your connection and Firestore rules, then reopen this page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
