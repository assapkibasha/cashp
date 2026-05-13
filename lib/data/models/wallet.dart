import 'wallet_type.dart';

class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  final String id;
  final String name;
  final WalletType type;
  final double balance;

  Wallet copyWith({double? balance}) {
    return Wallet(id: id, name: name, type: type, balance: balance ?? this.balance);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: walletTypeFromName(json['type'] as String? ?? 'needs'),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
