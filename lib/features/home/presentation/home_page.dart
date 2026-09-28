import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_page.dart';
import '../../seller/presentation/seller_dashboard_page.dart';
import 'widgets/featured_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.profile});

  final UserProfile? profile;

  bool get isVisitor => profile == null;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageController = PageController(viewportFraction: 0.90);
  final _authService = AuthService();
  int _selectedCategory = 0;
  int _navIndex = 0;

  static const _categories = [
    'All',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
  ];

  static const _featured = [
    FeaturedCardData(
      title: 'Fresh picks',
      subtitle: 'Discover what is trending across e-market.',
      icon: Icons.auto_awesome_rounded,
    ),
    FeaturedCardData(
      title: 'Electronics',
      subtitle: 'Smart devices, accessories and everyday tech.',
      icon: Icons.headphones_rounded,
    ),
    FeaturedCardData(
      title: 'Style drop',
      subtitle: 'New fashion arrivals selected for you.',
      icon: Icons.checkroom_rounded,
    ),
    FeaturedCardData(
      title: 'Home essentials',
      subtitle: 'Useful finds for a cleaner, calmer home.',
      icon: Icons.chair_alt_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  void _protectedAction(String authenticatedMessage) {
    if (widget.isVisitor) {
      _openAuthentication();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authenticatedMessage)),
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

  Future<void> _openSellerDashboard() async {
    final profile = widget.profile;
    if (profile == null || profile.role != UserRole.seller) return;

    await Navigator.of(context).push(
      smoothRoute(SellerDashboardPage(profile: profile)),
    );
  }

  void _onNavigationSelected(int index) {
    if (index == 1 &&
        widget.profile?.role == UserRole.seller) {
      _openSellerDashboard();
      return;
    }
    if (index == 2) {
      _protectedAction('Saved products arrive in a later LOT.');
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
                    onPressed: () => _protectedAction(
                      'Your cart will be implemented in LOT 6.',
                    ),
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
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Featured market',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.1,
                              ),
                            ),
                          ),
                          Text(
                            'Swipe →',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final selected = index == _selectedCategory;
                            return ChoiceChip(
                              label: Text(_categories[index]),
                              selected: selected,
                              showCheckmark: false,
                              selectedColor: AppColors.ink,
                              backgroundColor: AppColors.canvas,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide.none,
                              onSelected: (_) => setState(
                                () => _selectedCategory = index,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 330,
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _featured.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FeaturedCard(data: _featured[index])
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideX(begin: 0.06, end: 0),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: _featured.length,
                          effect: const ExpandingDotsEffect(
                            dotHeight: 7,
                            dotWidth: 7,
                            expansionFactor: 3.2,
                            activeDotColor: AppColors.accent,
                            dotColor: AppColors.line,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Popular products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          widget.profile?.role == UserRole.seller
                              ? 'Seller tools are ready in LOT 4. Open Market or your profile to manage products, stock, prices and visibility.'
                              : 'The live Firestore catalogue arrives in LOT 5. Authentication and persistent roles are already connected.',
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
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
