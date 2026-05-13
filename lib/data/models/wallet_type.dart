enum WalletType {
  needs,
  savings,
  wants;

  String get label {
    switch (this) {
      case WalletType.needs:
        return 'Needs';
      case WalletType.savings:
        return 'Savings';
      case WalletType.wants:
        return 'Wants';
    }
  }
}

WalletType walletTypeFromName(String value) {
  return WalletType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => WalletType.needs,
  );
}
