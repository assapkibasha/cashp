import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cashguard_repository.dart';
import 'data/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await CashguardRepository.create();
  final authRepository = AuthRepository(apiClient: ApiClient());
  await authRepository.load();
  runApp(CashguardApp(repository: repository, authRepository: authRepository));
}
