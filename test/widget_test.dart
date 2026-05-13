import 'package:cashguard/app/app.dart';
import 'package:cashguard/data/repositories/auth_repository.dart';
import 'package:cashguard/data/repositories/cashguard_repository.dart';
import 'package:cashguard/data/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CashGuard starts with onboarding when setup is incomplete', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final repository = await CashguardRepository.create();

    final authRepository = AuthRepository(apiClient: ApiClient());
    await authRepository.load();

    await tester.pumpWidget(CashguardApp(repository: repository, authRepository: authRepository));

    expect(find.text('CashGuard'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
