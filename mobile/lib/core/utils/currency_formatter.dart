import 'package:intl/intl.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';

abstract final class CurrencyFormatter {
  static String format(
    double amount, {
    required String currency,
    bool compact = false,
    bool showSign = false,
  }) {
    final symbol = AppConstants.currencySymbols[currency] ?? currency;
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formatted;
    if (compact && absAmount >= 1000) {
      formatted = _compactFormat(absAmount, currency);
    } else {
      final decimalDigits = _decimalDigits(currency);
      formatted = NumberFormat.currency(
        symbol: '',
        decimalDigits: decimalDigits,
      ).format(absAmount);
    }

    final buffer = StringBuffer();
    if (showSign && !isNegative && amount > 0) buffer.write('+');
    if (isNegative) buffer.write('-');
    buffer.write(symbol);
    buffer.write(formatted);

    return buffer.toString();
  }

  static String _compactFormat(double amount, String currency) {
    if (amount >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(1)}B';
    } else if (amount >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(1)}M';
    } else if (amount >= 1e3) {
      return '${(amount / 1e3).toStringAsFixed(1)}K';
    }
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: _decimalDigits(currency),
    ).format(amount);
  }

  static int _decimalDigits(String currency) {
    const zeroDecimalCurrencies = {'KRW', 'JPY'};
    return zeroDecimalCurrencies.contains(currency) ? 0 : 2;
  }

  static String symbolFor(String currency) {
    return AppConstants.currencySymbols[currency] ?? currency;
  }
}
