import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final auth = AuthScope.of(context);
      if (_register) {
        await auth.register(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text,
        );
      } else {
        await auth.login(email: _email.text.trim(), password: _password.text);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = '${error.message} (${error.statusCode})',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _connectionErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _connectionErrorMessage(Object error) {
    return 'Could not reach the CashGuard API at http://127.0.0.1:8080. '
        'Make sure the server is running, then try again.\n\n$error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 520 ? 22.0 : 32.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 32,
                  ),
                  children: [
                    Text(
                      'CashGuard',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _register
                          ? 'Create your secure money profile.'
                          : 'Sign in to your money profile.',
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_register) ...[
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Name optional',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) =>
                                value != null && value.contains('@')
                                ? null
                                : 'Enter a valid email',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            validator: (value) =>
                                value != null && value.length >= 8
                                ? null
                                : 'Use at least 8 characters',
                          ),
                          const SizedBox(height: 22),
                          if (_errorMessage != null) ...[
                            _AuthError(message: _errorMessage!),
                            const SizedBox(height: 14),
                          ],
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(
                              _loading
                                  ? 'Please wait...'
                                  : _register
                                  ? 'Create account'
                                  : 'Sign in',
                            ),
                          ),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                    _register = !_register;
                                    _errorMessage = null;
                                  }),
                            child: Text(
                              _register
                                  ? 'I already have an account'
                                  : 'Create a new account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
