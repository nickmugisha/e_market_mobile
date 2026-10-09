import 'package:flutter/material.dart';
import '../../../core/services/external_contact_service.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/product.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/domain/user_profile.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.profile,
    this.initialOrder,
  });

  final String orderId;
  final UserProfile profile;
  final MarketOrder? initialOrder;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _orders = OrderRepository();
  final _products = ProductRepository();
  final _contact = const ExternalContactService();

  bool _updating = false;
  bool _openingWhatsApp = false;

  Future<void> _transition(OrderStatus target) async {
    if (_updating) return;

    setState(() => _updating = true);
    try {
      await _orders.sellerTransition(
        orderId: widget.orderId,
        sellerId: widget.profile.uid,
        targetStatus: target,
      );
    } on OrderFailure catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not update the order. Please try again.');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _confirmTransition({
    required OrderStatus target,
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _transition(target);
    }
  }

  Future<void> _sendOrderWhatsApp(
    MarketOrder order,
    List<OrderItem> items,
  ) async {
    if (_openingWhatsApp) return;

    if (items.isEmpty) {
      _showMessage('The order has no items to send.');
      return;
    }

    setState(() => _openingWhatsApp = true);

    try {
      final activeProducts = await _products.fetchActiveProductsFromServer();

      Product? contactProduct;

      for (final product in activeProducts) {
        if (product.id == items.first.productId &&
            product.sellerWhatsapp.trim().isNotEmpty) {
          contactProduct = product;
          break;
        }
      }

      if (contactProduct == null) {
        for (final product in activeProducts) {
          if (product.sellerId == order.sellerId &&
              product.sellerWhatsapp.trim().isNotEmpty) {
            contactProduct = product;
            break;
          }
        }
      }

      if (contactProduct == null) {
        _showMessage('The seller WhatsApp number is unavailable.');
        return;
      }

      await _contact.openWhatsApp(
        phone: contactProduct.sellerWhatsapp,
        message: _buildWhatsAppMessage(order, items),
      );
    } on FormatException {
      _showMessage('The seller WhatsApp number is invalid.');
    } on ExternalContactFailure catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Could not prepare the WhatsApp order message.');
    } finally {
      if (mounted) {
        setState(() => _openingWhatsApp = false);
      }
    }
  }

  String _buildWhatsAppMessage(MarketOrder order, List<OrderItem> items) {
    final message = StringBuffer()
      ..writeln('NEW ORDER')
      ..writeln()
      ..writeln('Order ID: ${order.id}')
      ..writeln('Client: ${order.clientName}')
      ..writeln('Phone: ${order.clientPhone}')
      ..writeln()
      ..writeln('Products:');

    for (final item in items) {
      message.writeln('- ${item.productName} x ${item.quantity}');
    }

    message
      ..writeln()
      ..writeln('Subtotal: ${_orderAmount(order, order.subtotal)}')
      ..writeln('Delivery: ${_orderAmount(order, order.deliveryFee)}')
      ..writeln('Total: ${_orderAmount(order, order.total)}')
      ..writeln('Delivery option: ${order.fulfillmentType.label}');

    if (order.fulfillmentType == FulfillmentType.delivery) {
      message.writeln('Location: ${order.deliveryAddress}');
    }

    message
      ..writeln('Payment: ${order.paymentMethod.label}')
      ..writeln('Payment status: ${order.paymentStatus.label}');

    return message.toString().trim();
  }

  String _orderAmount(MarketOrder order, double amount) {
    final decimals = order.currency.code == 'BIF' ? 0 : 2;

    return '${order.currency.code} '
        '${amount.toStringAsFixed(decimals)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MarketOrder?>(
      stream: _orders.watchOrder(widget.orderId),
      initialData: widget.initialOrder,
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return const _OrderUnavailable();
        }

        final order = orderSnapshot.data;
        if (order == null) {
          return const _OrderUnavailable();
        }

        final sellerMode = widget.profile.role == UserRole.seller;

        return Scaffold(
          backgroundColor: AppColors.canvasFor(context),
          appBar: AppBar(
            title: Text('Order #${_shortId(order.id)}'),
            backgroundColor: AppColors.surfaceFor(context),
            surfaceTintColor: AppColors.surfaceFor(context),
          ),
          body: StreamBuilder<List<OrderItem>>(
            stream: _orders.watchOrderItems(order.id),
            builder: (context, itemSnapshot) {
              final items = itemSnapshot.data ?? const <OrderItem>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  _OrderHeader(order: order),
                  const SizedBox(height: 14),
                  _InfoCard(order: order),
                  const SizedBox(height: 18),
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (itemSnapshot.connectionState == ConnectionState.waiting &&
                      !itemSnapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else if (itemSnapshot.hasError)
                    const Text(
                      'Could not load order items.',
                      style: TextStyle(color: AppColors.muted),
                    )
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderItemCard(item: item),
                      ),
                    ),

                  if (!sellerMode && items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openingWhatsApp
                            ? null
                            : () => _sendOrderWhatsApp(order, items),
                        icon: _openingWhatsApp
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.chat_rounded),
                        label: Text(
                          _openingWhatsApp
                              ? 'Opening WhatsApp...'
                              : 'Send Order via WhatsApp',
                        ),
                      ),
                    ),
                  ],
                  if (sellerMode) ...[
                    const SizedBox(height: 12),
                    _SellerActions(
                      status: order.status,
                      updating: _updating,
                      onConfirm: () => _confirmTransition(
                        target: OrderStatus.confirmed,
                        title: 'Confirm order?',
                        message:
                            'Current product stock will be checked again and reserved by decreasing stock.',
                      ),
                      onPrepare: () => _transition(OrderStatus.preparing),
                      onReady: () => _transition(OrderStatus.ready),
                      onComplete: () => _confirmTransition(
                        target: OrderStatus.completed,
                        title: 'Complete order?',
                        message:
                            'The order will be marked completed. Pending cash payment will also be marked paid.',
                      ),
                      onCancel: () => _confirmTransition(
                        target: OrderStatus.cancelled,
                        title: 'Cancel order?',
                        message: order.status == OrderStatus.pending
                            ? 'The pending order will be cancelled.'
                            : 'The order will be cancelled and reserved stock will be restored.',
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _shortId(String value) {
    if (value.length <= 7) return value;
    return value.substring(0, 7).toUpperCase();
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final MarketOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.accent,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.currency.code} ${_price(order.total)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              order.paymentStatus.label,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.order});

  final MarketOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _InfoLine(label: 'Client', value: order.clientName),
          _InfoLine(label: 'Phone', value: order.clientPhone),
          _InfoLine(label: 'Fulfillment', value: order.fulfillmentType.label),
          if (order.fulfillmentType == FulfillmentType.delivery)
            _InfoLine(label: 'Address', value: order.deliveryAddress),
          _InfoLine(label: 'Payment', value: order.paymentMethod.label),
          _InfoLine(label: 'Payment status', value: order.paymentStatus.label),
          _InfoLine(label: 'Payment ref.', value: order.paymentReference),
          _InfoLine(label: 'Items', value: '${order.itemCount}', last: true),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ProductImage(
            imageRef: item.imageRef,
            width: 72,
            height: 76,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${item.currency.code} ${_price(item.unitPrice)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.currency.code} ${_price(item.subtotal)}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _SellerActions extends StatelessWidget {
  const _SellerActions({
    required this.status,
    required this.updating,
    required this.onConfirm,
    required this.onPrepare,
    required this.onReady,
    required this.onComplete,
    required this.onCancel,
  });

  final OrderStatus status;
  final bool updating;
  final VoidCallback onConfirm;
  final VoidCallback onPrepare;
  final VoidCallback onReady;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    VoidCallback? primaryAction;
    String? primaryLabel;
    IconData? primaryIcon;

    switch (status) {
      case OrderStatus.pending:
        primaryAction = onConfirm;
        primaryLabel = 'Confirm & reserve stock';
        primaryIcon = Icons.check_rounded;
        break;
      case OrderStatus.confirmed:
        primaryAction = onPrepare;
        primaryLabel = 'Start preparing';
        primaryIcon = Icons.inventory_2_outlined;
        break;
      case OrderStatus.preparing:
        primaryAction = onReady;
        primaryLabel = 'Mark ready';
        primaryIcon = Icons.task_alt_rounded;
        break;
      case OrderStatus.ready:
        primaryAction = onComplete;
        primaryLabel = 'Complete order';
        primaryIcon = Icons.done_all_rounded;
        break;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        break;
    }

    final canCancel =
        status != OrderStatus.completed && status != OrderStatus.cancelled;

    if (primaryAction == null && !canCancel) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seller actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (primaryAction != null)
            FilledButton.icon(
              onPressed: updating ? null : primaryAction,
              icon: updating
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(primaryIcon),
              label: Text(primaryLabel!),
            ),
          if (canCancel) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: updating ? null : onCancel,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Cancel order'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderUnavailable extends StatelessWidget {
  const _OrderUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: AppColors.surfaceFor(context),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'This order is unavailable or you do not have permission to view it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
