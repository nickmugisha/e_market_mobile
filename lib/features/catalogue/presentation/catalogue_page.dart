import 'package:flutter/material.dart';

import '../../../core/currency/currency_service.dart';
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

enum _CatalogueSort {
  newest,
  priceLowHigh,
  priceHighLow,
  nameAZ;

  String get label => switch (this) {
    _CatalogueSort.newest => 'Newest',
    _CatalogueSort.priceLowHigh => 'Price: Low',
    _CatalogueSort.priceHighLow => 'Price: High',
    _CatalogueSort.nameAZ => 'Name A-Z',
  };

  IconData get icon => switch (this) {
    _CatalogueSort.newest => Icons.schedule_rounded,
    _CatalogueSort.priceLowHigh => Icons.south_rounded,
    _CatalogueSort.priceHighLow => Icons.north_rounded,
    _CatalogueSort.nameAZ => Icons.sort_by_alpha_rounded,
  };
}

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key, this.profile, this.initialCategoryId});

  final UserProfile? profile;
  final String? initialCategoryId;

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  final _products = ProductRepository();
  final _categories = CategoryRepository();
  final _search = TextEditingController();
  final _currencyService = const CurrencyService();

  String? _selectedCategoryId;
  bool _inStockOnly = false;
  _CatalogueSort _sort = _CatalogueSort.newest;

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
        const AuthPage(returnOnSuccess: true, showVisitorOption: false),
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

  void _clearFilters() {
    _search.clear();
    setState(() {
      _selectedCategoryId = null;
      _inStockOnly = false;
      _sort = _CatalogueSort.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasFor(context),
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: AppColors.surfaceFor(context),
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<MarketCategory>>(
        stream: _categories.watchActiveCategories(),
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? const <MarketCategory>[];

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

              final allProducts = productSnapshot.data ?? const <Product>[];
              final visibleProducts = CatalogueFilter.apply(
                products: allProducts,
                query: _search.text,
                categoryId: _selectedCategoryId,
                inStockOnly: _inStockOnly,
              ).toList();

              double normalizedPrice(Product product) {
                return _currencyService.convert(
                  amount: product.price,
                  from: product.currency,
                  to: MarketCurrency.bif,
                );
              }

              switch (_sort) {
                case _CatalogueSort.newest:
                  visibleProducts.sort((a, b) {
                    final aDate =
                        a.updatedAt ??
                        a.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                    final bDate =
                        b.updatedAt ??
                        b.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);

                    return bDate.compareTo(aDate);
                  });
                  break;

                case _CatalogueSort.priceLowHigh:
                  visibleProducts.sort(
                    (a, b) => normalizedPrice(a).compareTo(normalizedPrice(b)),
                  );
                  break;

                case _CatalogueSort.priceHighLow:
                  visibleProducts.sort(
                    (a, b) => normalizedPrice(b).compareTo(normalizedPrice(a)),
                  );
                  break;

                case _CatalogueSort.nameAZ:
                  visibleProducts.sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                  break;
              }

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  _CatalogueHero(resultCount: visibleProducts.length),
                  const SizedBox(height: 16),
                  _PremiumSearchField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _search.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Shop by category',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      Text(
                        '${categories.length + 1} choices',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 43,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _CategoryChip(
                          label: 'All',
                          icon: Icons.grid_view_rounded,
                          selected: _selectedCategoryId == null,
                          onTap: () =>
                              setState(() => _selectedCategoryId = null),
                        ),
                        for (final category in categories) ...[
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: category.name,
                            icon: _categoryIcon(category.name),
                            selected: _selectedCategoryId == category.id,
                            onTap: () => setState(
                              () => _selectedCategoryId = category.id,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _StockFilterButton(
                        selected: _inStockOnly,
                        onTap: () =>
                            setState(() => _inStockOnly = !_inStockOnly),
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                        value: _sort,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sort = value);
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${visibleProducts.length} result${visibleProducts.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
                        final aspectRatio = constraints.maxWidth >= 720
                            ? 0.78
                            : 0.67;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleProducts.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 13,
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

  IconData _categoryIcon(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('fashion') ||
        normalized.contains('style') ||
        normalized.contains('cloth')) {
      return Icons.checkroom_rounded;
    }
    if (normalized.contains('elect') ||
        normalized.contains('tech') ||
        normalized.contains('phone')) {
      return Icons.devices_rounded;
    }
    if (normalized.contains('beauty') || normalized.contains('care')) {
      return Icons.auto_awesome_rounded;
    }
    if (normalized.contains('home') || normalized.contains('house')) {
      return Icons.chair_alt_rounded;
    }

    return Icons.local_mall_outlined;
  }
}

class _CatalogueHero extends StatelessWidget {
  const _CatalogueHero({required this.resultCount});

  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -54,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              right: 22,
              bottom: -22,
              child: Transform.rotate(
                angle: -0.16,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 104,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURATED MARKETPLACE',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Find your\nnext good find.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$resultCount item${resultCount == 1 ? '' : 's'} available for this view',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSearchField extends StatelessWidget {
  const _PremiumSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceFor(context),
          hintText: 'Search products, categories, sellers...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.canvasFor(context),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 18),
                )
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.3),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.ink : AppColors.line),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.accent,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockFilterButton extends StatelessWidget {
  const _StockFilterButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.inventory_2_outlined,
                size: 16,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
              const SizedBox(width: 7),
              Text(
                'In stock only',
                style: TextStyle(
                  color: selected ? AppColors.ink : AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final _CatalogueSort value;
  final ValueChanged<_CatalogueSort?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CatalogueSort>(
      initialValue: value,
      tooltip: 'Sort products',
      onSelected: onChanged,
      itemBuilder: (context) {
        return _CatalogueSort.values.map((option) {
          return PopupMenuItem<_CatalogueSort>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: option == value
                      ? AppColors.accentStrong
                      : AppColors.muted,
                ),
                const SizedBox(width: 10),
                Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: option == value
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value.icon, size: 16, color: AppColors.accentStrong),
            const SizedBox(width: 5),
            Text(
              value.label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
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
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 50, color: AppColors.accent),
          SizedBox(height: 12),
          Text(
            'No matching products',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Try another search, category or remove the in-stock filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
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
            Icon(Icons.cloud_off_rounded, size: 50, color: AppColors.accent),
            SizedBox(height: 12),
            Text(
              'Catalogue unavailable',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
