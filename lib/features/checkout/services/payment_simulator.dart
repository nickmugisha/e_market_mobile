import '../../orders/domain/order_models.dart';

class PaymentSimulationResult {
  const PaymentSimulationResult({
    required this.status,
    required this.message,
    required this.reference,
  });

  final PaymentStatus status;
  final String message;
  final String reference;
}

class PaymentSimulator {
  const PaymentSimulator();

  Future<PaymentSimulationResult> process(PaymentMethod method) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final reference =
        'SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    return switch (method) {
      PaymentMethod.cash => PaymentSimulationResult(
          status: PaymentStatus.pending,
          message: 'Cash payment will be completed at delivery or pickup.',
          reference: reference,
        ),
      PaymentMethod.mobileMoney => PaymentSimulationResult(
          status: PaymentStatus.paid,
          message: 'Mobile Money payment simulated successfully.',
          reference: reference,
        ),
      PaymentMethod.card => PaymentSimulationResult(
          status: PaymentStatus.paid,
          message: 'Card payment simulated successfully.',
          reference: reference,
        ),
    };
  }
}
