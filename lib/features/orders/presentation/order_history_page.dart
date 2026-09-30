import 'package:flutter/material.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_profile.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatelessWidget {
  OrderHistoryPage({
    super.key,
    required this.profile,
  });

  final UserProfile profile;
  final OrderRepository _orders = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final sellerMode = profile.role == UserRole.seller;
    final stream = sellerMode
        ? _orders.watchSellerOrders(profile.uid)
        : _orders.watchClientOrders(profile.uid);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(sellerMode ? 'Seller orders' : 'My orders'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<List<MarketOrder>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _OrdersMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Orders unavailable',
              message: 'Check your connection and Firestore permissions.',
            );
          }

          final orders = snapshot.data ?? const <MarketOrder>[];
          if (orders.isEmpty) {
            return _OrdersMessage(
              icon: Icons.receipt_long_outlined,
              title: sellerMode ? 'No incoming orders' : 'No orders yet',
              message: sellerMode
                  ? 'Client orders for your products will appear here.'
                  : 'Your completed checkout orders will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 80),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                sellerMode: sellerMode,
                onTap: () {
                  Navigator.of(context).push(
                    smoothRoute(
                      OrderDetailPage(
                        orderId: order.id,
                        profile: profile,
                        initialOrder: order,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.sellerMode,
    required this.onTap,
  });

  final MarketOrder order;
  final bool sellerMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerMode
                          ? order.clientName
                          : 'Order #${_shortId(order.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}'
                      ' • ${order.fulfillmentType.label}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.currency.code} ${_price(order.total)}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: order.status),
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String value) {
    if (value.length <= 7) return value;
    return value.substring(0, 7).toUpperCase();
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: status == OrderStatus.cancelled
            ? AppColors.canvas
            : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status == OrderStatus.cancelled
              ? AppColors.muted
              : AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({
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
              textAlign: TextAlign.center,
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
