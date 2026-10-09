import 'package:flutter/material.dart';

import '../../../core/currency/currency_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/domain/user_profile.dart';
import '../../cart/data/cart_repository.dart';
import '../../catalogue/data/product_repository.dart';
import '../../catalogue/domain/product.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/presentation/order_detail_page.dart';
import '../domain/checkout_draft.dart';
import '../domain/checkout_validator.dart';
import '../services/payment_simulator.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.profile,
    required this.initialDisplayCurrency,
  });

  final UserProfile profile;
  final MarketCurrency initialDisplayCurrency;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _cart = CartRepository();
  final _products = ProductRepository();
  final _paymentSimulator = const PaymentSimulator();
  final _orders = OrderRepository();
  final _currencyService = const CurrencyService();

  FulfillmentType _fulfillment = FulfillmentType.delivery;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  late MarketCurrency _displayCurrency;

  bool _processing = false;
  bool _placingOrder = false;
  CheckoutDraft? _readyDraft;
  PaymentSimulationResult? _paymentResult;

  @override
  void initState() {
    super.initState();
    _displayCurrency = widget.initialDisplayCurrency;
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  String? _validateAddress(String? value) {
    if (_fulfillment == FulfillmentType.pickup) return null;
    if ((value ?? '').trim().length < 5) {
      return 'Enter a complete delivery address.';
    }
    return null;
  }

  Future<void> _reviewAndSimulatePayment() async {
    if (_processing) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processing = true;
      _readyDraft = null;
      _paymentResult = null;
    });

    try {
      final items = await _cart.fetchItemsFromServer(widget.profile.uid);
      final activeProducts = await _products.fetchActiveProductsFromServer();

      final validation = CheckoutValidator.validate(
        items: items,
        activeProducts: activeProducts,
        fulfillmentType: _fulfillment,
        deliveryAddress: _address.text,
      );

      if (!validation.isValid) {
        if (!mounted) return;
        await _showValidationErrors(validation.errors);
        return;
      }

      final displayTotal = items.fold<double>(
        0,
        (sum, item) =>
            sum +
            _currencyService.convert(
              amount: item.subtotal,
              from: item.currency,
              to: _displayCurrency,
            ),
      );

      final paymentResult = await _paymentSimulator.process(_paymentMethod);

      final draft = CheckoutDraft.fromValidatedCart(
        profile: widget.profile,
        items: items,
        fulfillmentType: _fulfillment,
        deliveryAddress: _address.text,
        paymentMethod: _paymentMethod,
        paymentStatus: paymentResult.status,
        displayCurrency: _displayCurrency,
        displayTotal: displayTotal,
      );

      if (!mounted) return;

      setState(() {
        _readyDraft = draft;
        _paymentResult = paymentResult;
      });
    } on CartFailure catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Checkout validation could not reach Firebase. Try again when the connection is available.',
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _placeOrder() async {
    final draft = _readyDraft;
    final paymentResult = _paymentResult;

    if (draft == null || paymentResult == null || _placingOrder) return;

    if (draft.paymentStatus == PaymentStatus.failed) {
      _showMessage(
        'Payment failed. Choose another payment method and review the order again.',
      );
      return;
    }

    setState(() => _placingOrder = true);

    try {
      final orderId = await _orders.placeOrder(
        draft: draft,
        paymentReference: paymentResult.reference,
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              OrderDetailPage(orderId: orderId, profile: widget.profile),
        ),
      );
    } on OrderFailure catch (error) {
      _showMessage(error.message);
      if (mounted) {
        setState(() {
          _readyDraft = null;
          _paymentResult = null;
        });
      }
    } catch (_) {
      _showMessage(
        'Could not create the order. The cart was not intentionally cleared.',
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  Future<void> _showValidationErrors(List<String> errors) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cart changed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checkout was stopped because the latest cart/stock check found:',
            ),
            const SizedBox(height: 10),
            ...errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('â€¢ $error'),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review cart'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasFor(context),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.surfaceFor(context),
        surfaceTintColor: AppColors.surfaceFor(context),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 130),
          children: [
            _CheckoutHeader(profile: widget.profile),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Fulfillment',
              subtitle: 'Choose how you want to receive the order.',
              child: Column(
                children: [
                  _SelectionTile(
                    selected: _fulfillment == FulfillmentType.delivery,
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery',
                    subtitle:
                        'Enter the address where the seller should deliver.',
                    onTap: _processing
                        ? null
                        : () {
                            setState(() {
                              _fulfillment = FulfillmentType.delivery;
                              _readyDraft = null;
                              _paymentResult = null;
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  _SelectionTile(
                    selected: _fulfillment == FulfillmentType.pickup,
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Pickup',
                    subtitle:
                        'Pickup details will be confirmed with the seller.',
                    onTap: _processing
                        ? null
                        : () {
                            setState(() {
                              _fulfillment = FulfillmentType.pickup;
                              _readyDraft = null;
                              _paymentResult = null;
                            });
                          },
                  ),
                  if (_fulfillment == FulfillmentType.delivery) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address,
                      minLines: 2,
                      maxLines: 3,
                      enabled: !_processing,
                      validator: _validateAddress,
                      onChanged: (_) {
                        if (_readyDraft != null) {
                          setState(() => _readyDraft = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Delivery address',
                        hintText: 'Area, avenue/street and useful landmark',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Payment',
              subtitle: 'Choose your preferred payment method.',
              child: Column(
                children: [
                  _SelectionTile(
                    selected: _paymentMethod == PaymentMethod.cash,
                    icon: Icons.payments_outlined,
                    title: 'Cash',
                    subtitle: 'Pay at delivery or pickup.',
                    onTap: _processing
                        ? null
                        : () => _selectPayment(PaymentMethod.cash),
                  ),
                  const SizedBox(height: 8),
                  _SelectionTile(
                    selected: _paymentMethod == PaymentMethod.mobileMoney,
                    icon: Icons.phone_android_rounded,
                    title: 'Mobile Money',
                    subtitle: 'Simulated instant payment.',
                    onTap: _processing
                        ? null
                        : () => _selectPayment(PaymentMethod.mobileMoney),
                  ),
                  const SizedBox(height: 8),
                  _SelectionTile(
                    selected: _paymentMethod == PaymentMethod.card,
                    icon: Icons.credit_card_rounded,
                    title: 'Card',
                    subtitle: 'Simulated card authorization.',
                    onTap: _processing
                        ? null
                        : () => _selectPayment(PaymentMethod.card),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Checkout currency',
              subtitle: 'Choose the currency used for your order summary.',
              child: DropdownButtonFormField<MarketCurrency>(
                initialValue: _displayCurrency,
                items: MarketCurrency.values
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency.code),
                      ),
                    )
                    .toList(),
                onChanged: _processing
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _displayCurrency = value;
                          _readyDraft = null;
                        });
                      },
                decoration: const InputDecoration(
                  labelText: 'Display currency',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                ),
              ),
            ),
            if (_readyDraft != null && _paymentResult != null) ...[
              const SizedBox(height: 18),
              _ReadyForOrderCard(
                draft: _readyDraft!,
                paymentResult: _paymentResult!,
                currencyService: _currencyService,
                placingOrder: _placingOrder,
                onPlaceOrder: _placeOrder,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: FilledButton.icon(
          onPressed: _processing ? null : _reviewAndSimulatePayment,
          icon: _processing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.verified_outlined),
          label: Text(
            _processing
                ? 'Reviewing order...'
                : _readyDraft == null
                ? 'Review order'
                : 'Update order review',
          ),
        ),
      ),
    );
  }

  void _selectPayment(PaymentMethod value) {
    setState(() {
      _paymentMethod = value;
      _readyDraft = null;
      _paymentResult = null;
    });
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.profile});

  final UserProfile profile;

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
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.accent,
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checkout for',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : AppColors.canvas,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.accent : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.accent : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyForOrderCard extends StatelessWidget {
  const _ReadyForOrderCard({
    required this.draft,
    required this.paymentResult,
    required this.currencyService,
    required this.placingOrder,
    required this.onPlaceOrder,
  });

  final CheckoutDraft draft;
  final PaymentSimulationResult paymentResult;
  final CurrencyService currencyService;
  final bool placingOrder;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final paid = draft.paymentStatus == PaymentStatus.paid;
    final failed = draft.paymentStatus == PaymentStatus.failed;

    final totalQuantity = draft.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review your order',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$totalQuantity item${totalQuantity == 1 ? '' : 's'} ready for checkout',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvasFor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${draft.items.length} product${draft.items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...draft.items.map((item) {
            final displayUnitPrice = currencyService.convert(
              amount: item.unitPrice,
              from: item.currency,
              to: draft.displayCurrency,
            );

            final displaySubtotal = currencyService.convert(
              amount: item.subtotal,
              from: item.currency,
              to: draft.displayCurrency,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.canvasFor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProductImage(
                      imageRef: item.imageRef,
                      width: 74,
                      height: 74,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceFor(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Text(
                                  'Qty ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${currencyService.format(amount: displayUnitPrice, currency: draft.displayCurrency)} each',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyService.format(
                            amount: displaySubtotal,
                            currency: draft.displayCurrency,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 18),

          const Text(
            'Delivery & payment',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 6),

          _SummaryLine(
            label: 'Fulfillment',
            value: draft.fulfillmentType == FulfillmentType.delivery
                ? 'Delivery'
                : 'Pickup',
          ),

          if (draft.fulfillmentType == FulfillmentType.delivery &&
              draft.deliveryAddress.isNotEmpty)
            _SummaryLine(label: 'Address', value: draft.deliveryAddress),

          _SummaryLine(
            label: 'Payment',
            value: _paymentLabel(draft.paymentMethod),
          ),

          _SummaryLine(
            label: 'Payment status',
            value: paid ? 'Approved' : 'Pending',
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),

          _SummaryLine(
            label: 'Subtotal',
            value: currencyService.format(
              amount: draft.displaySubtotal,
              currency: draft.displayCurrency,
            ),
          ),
          _SummaryLine(
            label: 'Delivery fee',
            value: draft.deliveryFee == 0
                ? 'Free'
                : currencyService.format(
                    amount: draft.deliveryFee,
                    currency: draft.displayCurrency,
                  ),
          ),

          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order total',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Including all items',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                currencyService.format(
                  amount: draft.displayTotal,
                  currency: draft.displayCurrency,
                ),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  failed
                      ? Icons.error_outline_rounded
                      : paid
                      ? Icons.verified_rounded
                      : Icons.schedule_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failed
                            ? 'Payment failed'
                            : paid
                            ? 'Payment approved'
                            : 'Cash payment pending',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        paymentResult.message,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reference: ${paymentResult.reference}',
                        style: const TextStyle(
                          color: AppColors.muted,
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

          const SizedBox(height: 14),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 17,
                color: AppColors.muted,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Your order will be sent to the seller after you place it. Stock is reserved when the seller confirms the order.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  placingOrder || draft.paymentStatus == PaymentStatus.failed
                  ? null
                  : onPlaceOrder,
              icon: placingOrder
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(placingOrder ? 'Placing order...' : 'Place order'),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentLabel(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.mobileMoney => 'Mobile Money',
      PaymentMethod.card => 'Card',
    };
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
