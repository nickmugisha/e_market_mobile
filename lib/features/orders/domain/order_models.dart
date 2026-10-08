import '../../../core/firestore/firestore_value.dart';
import '../../catalogue/domain/product.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.ready => 'Ready',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
  };
}

enum FulfillmentType {
  delivery,
  pickup;

  static FulfillmentType fromValue(String? value) {
    return value == 'pickup'
        ? FulfillmentType.pickup
        : FulfillmentType.delivery;
  }

  String get label => switch (this) {
    FulfillmentType.delivery => 'Delivery',
    FulfillmentType.pickup => 'Pickup',
  };
}

enum PaymentMethod {
  cash('cash'),
  mobileMoney('mobile_money'),
  card('card');

  const PaymentMethod(this.value);

  final String value;

  static PaymentMethod fromValue(String? value) {
    return switch (value) {
      'mobile_money' => PaymentMethod.mobileMoney,
      'card' => PaymentMethod.card,
      _ => PaymentMethod.cash,
    };
  }

  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.mobileMoney => 'Mobile Money',
    PaymentMethod.card => 'Card',
  };
}

enum PaymentStatus {
  pending,
  paid,
  failed;

  static PaymentStatus fromValue(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get label => switch (this) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.paid => 'Paid',
    PaymentStatus.failed => 'Failed',
  };
}

class MarketOrder {
  const MarketOrder({
    required this.id,
    required this.clientId,
    required this.sellerId,
    required this.clientName,
    required this.clientPhone,
    required this.status,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentReference,
    required this.currency,
    required this.total,
    this.subtotal = 0,
    this.deliveryFee = 0,
    required this.itemCount,
    required this.deliveryAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;
  final String sellerId;
  final String clientName;
  final String clientPhone;
  final OrderStatus status;
  final FulfillmentType fulfillmentType;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String paymentReference;
  final MarketCurrency currency;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final int itemCount;
  final String deliveryAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MarketOrder.fromMap(String id, Map<String, dynamic> data) {
    return MarketOrder(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      clientPhone: data['clientPhone'] as String? ?? '',
      status: OrderStatus.fromValue(data['status'] as String?),
      fulfillmentType: FulfillmentType.fromValue(
        data['fulfillmentType'] as String?,
      ),
      paymentMethod: PaymentMethod.fromValue(data['paymentMethod'] as String?),
      paymentStatus: PaymentStatus.fromValue(data['paymentStatus'] as String?),
      paymentReference: data['paymentReference'] as String? ?? '',
      currency: MarketCurrency.fromValue(data['currency'] as String?),
      total: FirestoreValue.doubleValue(data['total']),
      subtotal: data.containsKey('subtotal')
          ? FirestoreValue.doubleValue(data['subtotal'])
          : FirestoreValue.doubleValue(data['total']),
      deliveryFee: data.containsKey('deliveryFee')
          ? FirestoreValue.doubleValue(data['deliveryFee'])
          : 0,
      itemCount: FirestoreValue.intValue(data['itemCount']),
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      createdAt: FirestoreValue.date(data['createdAt']),
      updatedAt: FirestoreValue.date(data['updatedAt']),
    );
  }
}

class OrderLineDraft {
  const OrderLineDraft({
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.imageRef,
    required this.quantity,
    required this.unitPrice,
    required this.currency,
  });

  final String productId;
  final String sellerId;
  final String productName;
  final String imageRef;
  final int quantity;
  final double unitPrice;
  final MarketCurrency currency;

  double get subtotal => unitPrice * quantity;
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.imageRef,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.currency,
  });

  final String id;
  final String productId;
  final String sellerId;
  final String productName;
  final String imageRef;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final MarketCurrency currency;

  factory OrderItem.fromMap(String id, Map<String, dynamic> data) {
    return OrderItem(
      id: id,
      productId: data['productId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      imageRef: data['imageRef'] as String? ?? '',
      quantity: FirestoreValue.intValue(data['quantity']),
      unitPrice: FirestoreValue.doubleValue(data['unitPrice']),
      subtotal: FirestoreValue.doubleValue(data['subtotal']),
      currency: MarketCurrency.fromValue(data['currency'] as String?),
    );
  }
}
