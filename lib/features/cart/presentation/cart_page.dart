import 'package:flutter/material.dart';

import '../../../core/currency/currency_service.dart';
import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/domain/user_profile.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/product.dart';
import '../../checkout/presentation/checkout_page.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';
import '../domain/cart_policy.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _cart = CartRepository();
  final _products = ProductRepository();
  final _currencyService = const CurrencyService();

  MarketCurrency _displayCurrency = MarketCurrency.bif;
  final Set<String> _busyItems = {};

  Future<void> _changeQuantity(
    CartItem item,
    int nextQuantity,
  ) async {
    if (_busyItems.contains(item.productId)) return;

    setState(() => _busyItems.add(item.productId));
    try {
      await _cart.setQuantity(
        clientUid: widget.profile.uid,
        productId: item.productId,
        quantity: nextQuantity,
      );
    } on CartFailure catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not update the cart. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.productId));
      }
    }
  }

  Future<void> _remove(CartItem item) async {
    if (_busyItems.contains(item.productId)) return;

    setState(() => _busyItems.add(item.productId));
    try {
      await _cart.removeItem(
        clientUid: widget.profile.uid,
        productId: item.productId,
      );
    } catch (_) {
      _showMessage('Could not remove the item.');
    } finally {
      if (mounted) {
        setState(() => _busyItems.remove(item.productId));
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'All products will be removed from your current seller cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _cart.clear(widget.profile.uid);
    } catch (_) {
      _showMessage('Could not clear the cart.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile.role != UserRole.client) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Cart'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'The shopping cart is available to client accounts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Your cart'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cart.watchItems(widget.profile.uid),
        builder: (context, cartSnapshot) {
          if (cartSnapshot.connectionState == ConnectionState.waiting &&
              !cartSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartSnapshot.hasError) {
            return const _CartMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Cart unavailable',
              message: 'Check your connection and try again later.',
            );
          }

          final items = cartSnapshot.data ?? const <CartItem>[];
          if (items.isEmpty) {
            return const _CartMessage(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Browse the marketplace and add a product you like.',
            );
          }

          return StreamBuilder<List<Product>>(
            stream: _products.watchActiveProducts(),
            builder: (context, productSnapshot) {
              final activeProducts =
                  productSnapshot.data ?? const <Product>[];
              final productsById = {
                for (final product in activeProducts) product.id: product,
              };
              final issues = CartPolicy.validateStock(
                items: items,
                activeProducts: activeProducts,
              );
              final issuesByProduct = {
                for (final issue in issues) issue.productId: issue,
              };

              final total = items.fold<double>(
                0,
                (sum, item) =>
                    sum +
                    _currencyService.convert(
                      amount: item.subtotal,
                      from: item.currency,
                      to: _displayCurrency,
                    ),
              );

              final firstProduct = productsById[items.first.productId];
              final sellerName =
                  firstProduct?.displaySellerName ?? 'Current seller';

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 80),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Single-seller cart',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _clearCart,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Display currency',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DropdownButton<MarketCurrency>(
                        value: _displayCurrency,
                        items: MarketCurrency.values
                            .map(
                              (currency) => DropdownMenuItem(
                                value: currency,
                                child: Text(currency.code),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _displayCurrency = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final currentProduct = productsById[item.productId];
                    final issue = issuesByProduct[item.productId];
                    final busy = _busyItems.contains(item.productId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CartItemCard(
                        item: item,
                        currentProduct: currentProduct,
                        displayCurrency: _displayCurrency,
                        currencyService: _currencyService,
                        issue: issue,
                        busy: busy,
                        onDecrease: () =>
                            _changeQuantity(item, item.quantity - 1),
                        onIncrease: currentProduct != null &&
                                item.quantity < currentProduct.stock
                            ? () => _changeQuantity(
                                  item,
                                  item.quantity + 1,
                                )
                            : null,
                        onRemove: () => _remove(item),
                      ),
                    );
                  }),
                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cart needs attention',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...issues.map(
                            (issue) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${issue.message}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Cart total',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _currencyService.format(
                            amount: total,
                            currency: _displayCurrency,
                          ),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: issues.isEmpty
                        ? () {
                            Navigator.of(context).push(
                              smoothRoute(
                                CheckoutPage(
                                  profile: widget.profile,
                                  initialDisplayCurrency: _displayCurrency,
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue to checkout'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prices are converted using fixed BIF-based demo rates in LOT 6.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.currentProduct,
    required this.displayCurrency,
    required this.currencyService,
    required this.issue,
    required this.busy,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final Product? currentProduct;
  final MarketCurrency displayCurrency;
  final CurrencyService currencyService;
  final CartIssue? issue;
  final bool busy;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final convertedUnitPrice = currencyService.convert(
      amount: item.unitPrice,
      from: item.currency,
      to: displayCurrency,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: issue == null ? AppColors.line : AppColors.accent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(
            imageRef: item.imageRef,
            width: 86,
            height: 100,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : onRemove,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  currencyService.format(
                    amount: convertedUnitPrice,
                    currency: displayCurrency,
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (issue != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    issue!.message,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ] else if (currentProduct != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${currentProduct!.stock} available',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: busy ? null : onDecrease,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                    IconButton.outlined(
                      onPressed: busy ? null : onIncrease,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartMessage extends StatelessWidget {
  const _CartMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.accent),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
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
      ),
    );
  }
}
