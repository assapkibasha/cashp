import '../../data/models/wallet_type.dart';

class AppConstants {
  static const appName = 'CashGuard';
  static const defaultCurrency = 'RWF';
  static const incomeSources = [
    'Salary',
    'Client project',
    'Gift',
    'Business',
    'Other',
  ];

  static const walletOrder = [
    WalletType.needs,
    WalletType.savings,
    WalletType.wants,
  ];
}
