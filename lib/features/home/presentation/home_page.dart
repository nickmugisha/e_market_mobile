import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_page.dart';
import '../../cart/presentation/cart_page.dart';
import '../../catalogue/data/category_repository.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/market_category.dart';
import '../../catalogue/domain/product.dart';
import '../../catalogue/presentation/catalogue_page.dart';
import '../../catalogue/presentation/product_detail_page.dart';
import '../../catalogue/presentation/widgets/catalogue_product_card.dart';
import '../../orders/presentation/order_history_page.dart';
import '../../profile/presentation/edit_profile_page.dart';
import '../../saved/presentation/saved_products_page.dart';
import '../../seller/presentation/seller_dashboard_page.dart';
import 'widgets/featured_card.dart';
import 'widgets/stacked_featured_deck.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.profile});

  final UserProfile? profile;

  bool get isVisitor => profile == null;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _products = ProductRepository();
  final _categories = CategoryRepository();
  int _navIndex = 0;

  static const _featured = [
    FeaturedCardData(
      eyebrow: 'Curated for you',
      title: 'Fresh picks',
      subtitle: 'Discover standout finds selected from across e-market.',
      icon: Icons.auto_awesome_rounded,
      gradientStart: Color(0xFF101826),
      gradientEnd: Color(0xFF243A59),
      accent: Color(0xFF4C9BFF),
    ),
    FeaturedCardData(
      eyebrow: 'Tech edit',
      title: 'Electronics',
      subtitle: 'Smart devices, accessories and everyday technology.',
      icon: Icons.headphones_rounded,
      gradientStart: Color(0xFF073B4C),
      gradientEnd: Color(0xFF116B86),
      accent: Color(0xFF27B8E6),
    ),
    FeaturedCardData(
      eyebrow: 'New season',
      title: 'Style drop',
      subtitle: 'Fresh fashion arrivals with a clean premium look.',
      icon: Icons.checkroom_rounded,
      gradientStart: Color(0xFF2A1738),
      gradientEnd: Color(0xFF6F3A88),
      accent: Color(0xFFC16BF0),
    ),
    FeaturedCardData(
      eyebrow: 'Everyday upgrade',
      title: 'Home essentials',
      subtitle: 'Useful finds for a cleaner, calmer and smarter home.',
      icon: Icons.chair_alt_rounded,
      gradientStart: Color(0xFF153229),
      gradientEnd: Color(0xFF2D6B59),
      accent: Color(0xFF55C59F),
    ),
  ];

  Future<void> _openAuthentication() async {
    await Navigator.of(context).push(
      smoothRoute(
        const AuthPage(
          returnOnSuccess: true,
          showVisitorOption: false,
        ),
      ),
    );
  }

  Future<void> _showProfile() async {
    if (widget.isVisitor) {
      await _openAuthentication();
      return;
    }

    final profile = widget.profile!;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.role.label} | ${profile.email}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                _ProfileLine(
                  icon: Icons.phone_outlined,
                  label: profile.phone,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openEditProfile();
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile'),
                  ),
                ),
                if (profile.role == UserRole.client) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openOrders();
                      },
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('My orders'),
                    ),
                  ),
                ],
                if (profile.role == UserRole.seller) ...[
                  const SizedBox(height: 10),
                  _ProfileLine(
                    icon: Icons.chat_outlined,
                    label: profile.whatsappNumber,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openSellerDashboard();
                      },
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Open seller dashboard'),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _authService.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditProfile() async {
    final profile = widget.profile;
    if (profile == null) return;

    await Navigator.of(context).push(
      smoothRoute(EditProfilePage(profile: profile)),
    );
  }

  Future<void> _openSaved() async {
    final profile = widget.profile;

    if (profile == null) {
      await _openAuthentication();
      return;
    }

    if (profile.role != UserRole.client) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved products are available to client accounts.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      smoothRoute(SavedProductsPage(profile: profile)),
    );
  }

  Future<void> _openOrders() async {
    final profile = widget.profile;
    if (profile == null) return;

    await Navigator.of(context).push(
      smoothRoute(OrderHistoryPage(profile: profile)),
    );
  }

  Future<void> _openSellerDashboard() async {
    final profile = widget.profile;
    if (profile == null || profile.role != UserRole.seller) return;

    await Navigator.of(context).push(
      smoothRoute(SellerDashboardPage(profile: profile)),
    );
  }

  Future<void> _openCatalogue() {
    return Navigator.of(context).push(
      smoothRoute(CataloguePage(profile: widget.profile)),
    );
  }

  Future<void> _openCategory(MarketCategory category) {
    return Navigator.of(context).push(
      smoothRoute(
        CataloguePage(
          profile: widget.profile,
          initialCategoryId: category.id,
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
          onSignInRequested: _openAuthentication,
        ),
      ),
    );
  }

  Future<void> _openCart() async {
    final profile = widget.profile;

    if (profile == null) {
      await _openAuthentication();
      return;
    }

    if (profile.role != UserRole.client) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The shopping cart is available to client accounts.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      smoothRoute(CartPage(profile: profile)),
    );
  }

  void _onNavigationSelected(int index) {
    if (index == 1) {
      _openCatalogue();
      return;
    }
    if (index == 2) {
      _openSaved();
      return;
    }
    if (index == 3) {
      _showProfile();
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final firstName = profile?.firstName.trim();
    final greeting = widget.isVisitor
        ? 'Hello, visitor'
        : 'Hello, ${firstName == null || firstName.isEmpty ? 'there' : firstName}';
    final subtitle = widget.isVisitor
        ? 'Discover freely. Sign in only when you are ready.'
        : '${profile!.role.label} account | Firebase connected';

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PremiumHomeHeader(
              greeting: greeting,
              subtitle: subtitle,
              isVisitor: widget.isVisitor,
              roleLabel: profile?.role.label,
              onProfile: _showProfile,
              onCart: _openCart,
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeading(
                        eyebrow: 'DISCOVER',
                        title: 'Featured market',
                        actionLabel: 'Browse all',
                        onAction: _openCatalogue,
                      ),
                      const SizedBox(height: 14),
                      _HomeSearchCard(onTap: _openCatalogue),
                      const SizedBox(height: 18),
                      StreamBuilder<List<MarketCategory>>(
                        stream: _categories.watchActiveCategories(),
                        builder: (context, snapshot) {
                          final categories =
                              snapshot.data ?? const <MarketCategory>[];

                          return _HomeCategoryStrip(
                            categories: categories,
                            onAll: _openCatalogue,
                            onCategory: _openCategory,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      FeaturedCardDeck(
                        items: _featured,
                        onTap: _openCatalogue,
                      ),
                      const SizedBox(height: 34),
                      _SectionHeading(
                        eyebrow: 'JUST IN',
                        title: 'Latest products',
                        actionLabel: 'View all',
                        onAction: _openCatalogue,
                        compact: true,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Product>>(
                        stream: _products.watchActiveProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const SizedBox(
                              height: 170,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const _HomeCatalogueMessage(
                              icon: Icons.cloud_off_rounded,
                              title: 'Catalogue unavailable',
                              message:
                                  'Check your connection and try the Market page again.',
                            );
                          }

                          final products =
                              snapshot.data ?? const <Product>[];

                          if (products.isEmpty) {
                            return const _HomeCatalogueMessage(
                              icon: Icons.inventory_2_outlined,
                              title: 'No products yet',
                              message:
                                  'Products added by sellers will appear here automatically.',
                            );
                          }

                          final latest = products.take(4).toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: latest.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 13,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.67,
                            ),
                            itemBuilder: (context, index) {
                              final product = latest[index];
                              return CatalogueProductCard(
                                product: product,
                                onTap: () => _openProduct(product),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavigationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}


class _PremiumHomeHeader extends StatelessWidget {
  const _PremiumHomeHeader({
    required this.greeting,
    required this.subtitle,
    required this.isVisitor,
    required this.roleLabel,
    required this.onProfile,
    required this.onCart,
  });

  final String greeting;
  final String subtitle;
  final bool isVisitor;
  final String? roleLabel;
  final VoidCallback onProfile;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 146,
      child: Stack(
        children: [
          Positioned(
            right: -62,
            top: -72,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            right: 92,
            bottom: -44,
            child: Transform.rotate(
              angle: -0.30,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                _HeaderAvatar(
                  isVisitor: isVisitor,
                  onTap: onProfile,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              greeting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            '',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.075),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Text(
                          isVisitor
                              ? 'EXPLORE MODE'
                              : '${roleLabel?.toUpperCase() ?? 'ACCOUNT'} | LIVE',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You are all caught up for now.'),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 7),
                _HeaderActionButton(
                  icon: Icons.shopping_bag_outlined,
                  onTap: onCart,
                  accent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.isVisitor,
    required this.onTap,
  });

  final bool isVisitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 2,
            ),
          ),
          child: Icon(
            isVisitor ? Icons.explore_rounded : Icons.person_rounded,
            color: AppColors.ink,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent
          ? AppColors.accent
          : Colors.white.withValues(alpha: 0.085),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: accent
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 22 : 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? -0.7 : -1.15,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          iconAlignment: IconAlignment.end,
          icon: const Icon(
            Icons.arrow_outward_rounded,
            size: 16,
          ),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _HomeSearchCard extends StatelessWidget {
  const _HomeSearchCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.ink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search e-market',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Products, categories or sellers',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCategoryStrip extends StatelessWidget {
  const _HomeCategoryStrip({
    required this.categories,
    required this.onAll,
    required this.onCategory,
  });

  final List<MarketCategory> categories;
  final VoidCallback onAll;
  final ValueChanged<MarketCategory> onCategory;

  @override
  Widget build(BuildContext context) {
    final visible = categories.take(6).toList();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _HomeCategoryCard(
              label: 'All',
              icon: Icons.grid_view_rounded,
              onTap: onAll,
              featured: true,
            );
          }

          final category = visible[index - 1];
          return _HomeCategoryCard(
            label: category.name,
            icon: _categoryIcon(category.name),
            onTap: () => onCategory(category),
          );
        },
      ),
    );
  }

  static IconData _categoryIcon(String value) {
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
    if (normalized.contains('beauty') ||
        normalized.contains('care')) {
      return Icons.auto_awesome_rounded;
    }
    if (normalized.contains('home') ||
        normalized.contains('house')) {
      return Icons.chair_alt_rounded;
    }
    if (normalized.contains('food')) {
      return Icons.local_dining_rounded;
    }

    return Icons.local_mall_outlined;
  }
}

class _HomeCategoryCard extends StatelessWidget {
  const _HomeCategoryCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.featured = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: featured ? AppColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: featured ? AppColors.ink : AppColors.line,
            ),
            boxShadow: featured
                ? null
                : [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.035),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: featured ? Colors.white : AppColors.accent,
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: featured ? Colors.white : AppColors.ink,
                  fontSize: 10,
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

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _HomeCatalogueMessage extends StatelessWidget {
  const _HomeCatalogueMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
