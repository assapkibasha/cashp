import 'package:cashguard/data/models/user_settings.dart';
import 'package:cashguard/data/models/wallet_type.dart';
import 'package:cashguard/data/repositories/cashguard_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('income split, expense guard, goal contribution, and reload persistence work', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = await CashguardRepository.create();

    await repo.completeSetup(
      UserSettings.defaults().copyWith(
        setupCompleted: true,
        needsPercentage: 60,
        savingsPercentage: 20,
        wantsPercentage: 20,
      ),
    );
    await repo.addIncome(
      amount: 100000,
      source: 'Salary',
      date: DateTime(2026, 5, 7),
      note: '',
    );

    expect(repo.walletBalance(WalletType.needs), 60000);
    expect(repo.walletBalance(WalletType.savings), 20000);
    expect(repo.walletBalance(WalletType.wants), 20000);
    expect(repo.totalBalance, 100000);

    final blocked = await repo.addExpense(
      amount: 70000,
      category: 'Food',
      walletType: WalletType.needs,
      date: DateTime(2026, 5, 7),
      note: '',
    );
    expect(blocked, isNotNull);
    expect(repo.walletBalance(WalletType.needs), 60000);

    final saved = await repo.addExpense(
      amount: 4500,
      category: 'Food',
      walletType: WalletType.needs,
      date: DateTime(2026, 5, 7),
      note: '',
    );
    expect(saved, isNull);
    expect(repo.walletBalance(WalletType.needs), 55500);

    await repo.addGoal(name: 'Buy phone', targetAmount: 250000, currentSavedAmount: 30000);
    final contributionMessage = await repo.contributeToGoal(repo.goals.first, 5000);
    expect(contributionMessage, isNull);
    expect(repo.walletBalance(WalletType.savings), 15000);
    expect(repo.goals.first.savedAmount, 35000);
    expect(repo.transactions.length, 3);

    final reloaded = await CashguardRepository.create();
    expect(reloaded.setupCompleted, isTrue);
    expect(reloaded.walletBalance(WalletType.needs), 55500);
    expect(reloaded.goals.first.savedAmount, 35000);
  });
}
