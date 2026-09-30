import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_page.dart';
import '../../cart/presentation/cart_page.dart';
import '../../catalogue/data/product_repository.dart';
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
                  '${profile.role.label} • ${profile.email}',
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
    final greeting = widget.isVisitor
        ? 'Hello, visitor'
        : 'Hello, ${profile!.firstName}';
    final subtitle = widget.isVisitor
        ? 'Browse freely. Sign in when you are ready to buy.'
        : '${profile!.role.label} account • Firebase connected';

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showProfile,
                    child: const CircleAvatar(
                      radius: 23,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: _openCart,
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Featured market',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.1,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openCatalogue,
                            child: const Text('Browse all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _openCatalogue,
                        borderRadius: BorderRadius.circular(18),
                        child: const IgnorePointer(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Search products, categories, sellers...',
                              prefixIcon: Icon(Icons.search_rounded),
                              suffixIcon: Icon(Icons.tune_rounded),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FeaturedCardDeck(
                        items: _featured,
                        onTap: _openCatalogue,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Latest products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openCatalogue,
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Product>>(
                        stream: _products.watchActiveProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const SizedBox(
                              height: 150,
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
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
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
