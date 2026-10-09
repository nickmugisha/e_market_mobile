import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_profile.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/product.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';

abstract final class _NotificationReadState {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static final Map<String, Set<String>> _seenByUser = <String, Set<String>>{};

  static bool isSeen(String userId, String key) {
    return _seenByUser[userId]?.contains(key) ?? false;
  }

  static void markSeen(String userId, Iterable<String> keys) {
    final seen = _seenByUser.putIfAbsent(userId, () => <String>{});

    var changed = false;

    for (final key in keys) {
      if (seen.add(key)) {
        changed = true;
      }
    }

    if (changed) {
      revision.value++;
    }
  }
}

Future<void> showNotificationCenter(
  BuildContext context, {
  required UserProfile? profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceFor(context),
    builder: (context) {
      return _NotificationCenterSheet(profile: profile);
    },
  );
}

class MarketNotificationBell extends StatelessWidget {
  MarketNotificationBell({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final UserProfile? profile;
  final VoidCallback onTap;

  final OrderRepository _orders = OrderRepository();
  final ProductRepository _products = ProductRepository();

  bool _isActiveOrder(MarketOrder order) {
    return order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled;
  }

  Widget _buildUnreadButton({
    required String userId,
    required List<_Notice> notices,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: _NotificationReadState.revision,
      builder: (context, revision, child) {
        final unread = notices.where((notice) {
          return !_NotificationReadState.isSeen(userId, notice.key);
        }).length;

        return _NotificationButton(count: unread, onTap: onTap);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;

    if (currentProfile == null) {
      return _NotificationButton(count: 0, onTap: onTap);
    }

    if (currentProfile.role == UserRole.client) {
      return StreamBuilder<List<MarketOrder>>(
        stream: _orders.watchClientOrders(currentProfile.uid),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <MarketOrder>[];

          final notices = orders
              .where(_isActiveOrder)
              .take(8)
              .map(_Notice.fromClientOrder)
              .toList();

          return _buildUnreadButton(
            userId: currentProfile.uid,
            notices: notices,
          );
        },
      );
    }

    return StreamBuilder<List<MarketOrder>>(
      stream: _orders.watchSellerOrders(currentProfile.uid),
      builder: (context, orderSnapshot) {
        return StreamBuilder<List<Product>>(
          stream: _products.watchSellerProducts(currentProfile.uid),
          builder: (context, productSnapshot) {
            final orders = orderSnapshot.data ?? const <MarketOrder>[];

            final products = productSnapshot.data ?? const <Product>[];

            final orderNotices = orders
                .where(_isActiveOrder)
                .take(8)
                .map(_Notice.fromSellerOrder);

            final stockNotices = products
                .where((product) => product.active && product.stock <= 5)
                .map(_Notice.fromStock);

            return _buildUnreadButton(
              userId: currentProfile.uid,
              notices: [...stockNotices, ...orderNotices],
            );
          },
        );
      },
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 9 ? '9+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.085),
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.leafGlow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.leafGlow.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                displayCount,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationCenterSheet extends StatelessWidget {
  _NotificationCenterSheet({required this.profile});

  final UserProfile? profile;

  final OrderRepository _orders = OrderRepository();
  final ProductRepository _products = ProductRepository();

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;

    if (currentProfile == null) {
      return const _VisitorNotifications();
    }

    if (currentProfile.role == UserRole.client) {
      return StreamBuilder<List<MarketOrder>>(
        stream: _orders.watchClientOrders(currentProfile.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _NotificationError();
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _NotificationLoading();
          }

          final orders = snapshot.data ?? const <MarketOrder>[];

          final notices = orders
              .take(8)
              .map((order) => _Notice.fromClientOrder(order))
              .toList();

          return _NotificationBody(
            userId: currentProfile.uid,
            eyebrow: 'YOUR ACTIVITY',
            title: 'Notifications',
            subtitle:
                'Order updates appear here automatically as sellers process them.',
            notices: notices,
          );
        },
      );
    }

    return StreamBuilder<List<MarketOrder>>(
      stream: _orders.watchSellerOrders(currentProfile.uid),
      builder: (context, orderSnapshot) {
        return StreamBuilder<List<Product>>(
          stream: _products.watchSellerProducts(currentProfile.uid),
          builder: (context, productSnapshot) {
            if (orderSnapshot.hasError || productSnapshot.hasError) {
              return const _NotificationError();
            }

            final stillLoading =
                (orderSnapshot.connectionState == ConnectionState.waiting &&
                    !orderSnapshot.hasData) ||
                (productSnapshot.connectionState == ConnectionState.waiting &&
                    !productSnapshot.hasData);

            if (stillLoading) {
              return const _NotificationLoading();
            }

            final orders = orderSnapshot.data ?? const <MarketOrder>[];

            final products = productSnapshot.data ?? const <Product>[];

            final stockNotices = products
                .where((product) => product.active && product.stock <= 5)
                .map(_Notice.fromStock)
                .toList();

            final orderNotices = orders
                .take(8)
                .map(_Notice.fromSellerOrder)
                .toList();

            return _NotificationBody(
              userId: currentProfile.uid,
              eyebrow: 'SELLER ACTIVITY',
              title: 'Notifications',
              subtitle:
                  'New orders and stock alerts are gathered here in real time.',
              notices: [...stockNotices, ...orderNotices],
            );
          },
        );
      },
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({
    required this.userId,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.notices,
  });

  final String userId;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<_Notice> notices;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _NotificationReadState.markSeen(
        userId,
        notices.map((notice) => notice.key),
      );
    });

    final height = MediaQuery.sizeOf(context).height * 0.76;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: notices.isEmpty
                  ? const _EmptyNotifications()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      itemCount: notices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _NoticeCard(notice: notices[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice {
  const _Notice({
    required this.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });

  final String key;
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;

  factory _Notice.fromClientOrder(MarketOrder order) {
    final title = switch (order.status) {
      OrderStatus.pending => 'Order received',
      OrderStatus.confirmed => 'Order confirmed',
      OrderStatus.preparing => 'Your order is being prepared',
      OrderStatus.ready => 'Your order is ready',
      OrderStatus.completed => 'Order completed',
      OrderStatus.cancelled => 'Order cancelled',
    };

    final icon = switch (order.status) {
      OrderStatus.pending => Icons.schedule_rounded,
      OrderStatus.confirmed => Icons.check_circle_outline_rounded,
      OrderStatus.preparing => Icons.inventory_2_outlined,
      OrderStatus.ready => Icons.shopping_bag_outlined,
      OrderStatus.completed => Icons.done_all_rounded,
      OrderStatus.cancelled => Icons.cancel_outlined,
    };

    final color = order.status == OrderStatus.cancelled
        ? AppColors.danger
        : AppColors.accentStrong;

    return _Notice(
      key:
          'client-order:${order.id}:${order.status.name}:${order.paymentStatus.name}',
      icon: icon,
      title: title,
      message:
          'Order #${_shortId(order.id)} | '
          '${order.itemCount} '
          'item${order.itemCount == 1 ? '' : 's'} | '
          '${order.currency.code} ${_price(order.total)}',
      time: _formatTime(order.updatedAt ?? order.createdAt),
      color: color,
    );
  }

  factory _Notice.fromSellerOrder(MarketOrder order) {
    final isNew = order.status == OrderStatus.pending;

    return _Notice(
      key:
          'seller-order:${order.id}:${order.status.name}:${order.paymentStatus.name}',
      icon: isNew
          ? Icons.add_shopping_cart_rounded
          : Icons.receipt_long_outlined,
      title: isNew ? 'New order' : 'Order ${order.status.label.toLowerCase()}',
      message:
          '${order.clientName} | '
          '#${_shortId(order.id)} | '
          '${order.itemCount} '
          'item${order.itemCount == 1 ? '' : 's'} | '
          '${order.currency.code} ${_price(order.total)}',
      time: _formatTime(order.updatedAt ?? order.createdAt),
      color: order.status == OrderStatus.cancelled
          ? AppColors.danger
          : AppColors.accentStrong,
    );
  }

  factory _Notice.fromStock(Product product) {
    final soldOut = product.stock == 0;

    return _Notice(
      key: 'seller-stock:${product.id}:${product.stock}',
      icon: soldOut
          ? Icons.remove_shopping_cart_outlined
          : Icons.warning_amber_rounded,
      title: soldOut ? 'Product sold out' : 'Low stock',
      message: soldOut
          ? '${product.name} has no units left.'
          : '${product.name} has only '
                '${product.stock} '
                'unit${product.stock == 1 ? '' : 's'} remaining.',
      time: _formatTime(product.updatedAt ?? product.createdAt),
      color: soldOut ? AppColors.danger : AppColors.accentStrong,
    );
  }

  static String _shortId(String id) {
    if (id.length <= 7) {
      return id.toUpperCase();
    }

    return id.substring(0, 7).toUpperCase();
  }

  static String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  static String _formatTime(DateTime? value) {
    if (value == null) {
      return 'Live';
    }

    final local = value.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month} | '
        '$hour:$minute';
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _Notice notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.lineFor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: notice.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(notice.icon, color: notice.color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: TextStyle(
                          color: AppColors.textFor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notice.time,
                      style: TextStyle(
                        color: AppColors.mutedFor(context),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notice.message,
                  style: TextStyle(
                    color: AppColors.mutedFor(context),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.accentStrong,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You are all caught up',
              style: TextStyle(
                color: AppColors.textFor(context),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'New order activity and marketplace alerts will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedFor(context), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorNotifications extends StatelessWidget {
  const _VisitorNotifications();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.accentStrong,
                size: 34,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Your marketplace alerts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textFor(context),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to receive order updates and activity notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedFor(context),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLoading extends StatelessWidget {
  const _NotificationLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: SizedBox(
        height: 360,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 360,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.danger,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Notifications unavailable',
                  style: TextStyle(
                    color: AppColors.textFor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedFor(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
