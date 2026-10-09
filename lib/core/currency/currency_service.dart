import '../../features/catalogue/domain/product.dart';

class CurrencyService {
  const CurrencyService();

  // Fixed demo/fallback rates using BIF as the pivot.
  // LOT 6 intentionally keeps this dependency-free and deterministic.
  static const Map<MarketCurrency, double> _bifPerUnit = {
    MarketCurrency.bif: 1,
    MarketCurrency.usd: 2900,
    MarketCurrency.eur: 3150,
  };

  double convert({
    required double amount,
    required MarketCurrency from,
    required MarketCurrency to,
  }) {
    if (from == to) return amount;

    final bifValue = amount * _bifPerUnit[from]!;
    return bifValue / _bifPerUnit[to]!;
  }

  String format({required double amount, required MarketCurrency currency}) {
    final decimals = currency == MarketCurrency.bif ? 0 : 2;
    return '${currency.code} ${amount.toStringAsFixed(decimals)}';
  }
}
