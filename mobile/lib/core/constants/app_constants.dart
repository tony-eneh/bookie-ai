abstract final class AppConstants {
  static const String appName = 'BookieAI';
  static const String appTagline = 'Track nothing. Know everything.';
  static const String appVersion = '1.0.0';

  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const int pageSize = 20;
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 30);

  static const List<String> supportedCurrencies = [
    'NGN', 'USD', 'EUR', 'GBP', 'KRW', 'JPY', 'GHS', 'KES', 'ZAR', 'CAD',
    'AUD', 'INR', 'CNY',
  ];

  static const Map<String, String> currencySymbols = {
    'NGN': '₦',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'KRW': '₩',
    'JPY': '¥',
    'GHS': 'GH₵',
    'KES': 'KSh',
    'ZAR': 'R',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'INR': '₹',
    'CNY': '¥',
  };

  static const List<String> accountTypes = [
    'checking',
    'savings',
    'credit_card',
    'cash',
    'investment',
    'mobile_money',
    'digital_wallet',
  ];

  static const List<String> transactionTypes = [
    'income',
    'expense',
    'transfer',
  ];

  static const List<String> budgetPeriods = [
    'weekly',
    'monthly',
    'yearly',
  ];
}
