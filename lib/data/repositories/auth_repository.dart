import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_client.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'cashguard_auth_token';
  static const _emailKey = 'cashguard_auth_email';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  bool initialized = false;
  String? token;
  String? email;

  bool get isAuthenticated => token != null;

  Future<void> load() async {
    token = await _secureStorage.read(key: _tokenKey);
    email = await _secureStorage.read(key: _emailKey);
    initialized = true;
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final data = await _apiClient.post('/auth/register', {
      'email': email,
      'password': password,
      if (displayName != null && displayName.trim().isNotEmpty) 'displayName': displayName.trim(),
    });
    await _saveSession(data);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> logout() async {
    token = null;
    email = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _emailKey);
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    token = data['token'] as String;
    email = (data['user'] as Map<String, dynamic>)['email'] as String?;
    await _secureStorage.write(key: _tokenKey, value: token);
    if (email != null) await _secureStorage.write(key: _emailKey, value: email);
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthRepository> {
  const AuthScope({
    super.key,
    required AuthRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static AuthRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}
