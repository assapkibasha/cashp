import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl})
    : baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8080',
          );

  final String baseUrl;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
    );
    return _decode(response);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final data =
        jsonDecode(response.body.isEmpty ? '{}' : response.body)
            as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _errorMessage(data);
      throw ApiException(message, response.statusCode);
    }
    return data;
  }

  String _errorMessage(Map<String, dynamic> data) {
    final details = data['details'];
    if (details is List && details.isNotEmpty) {
      final messages = details
          .whereType<Map<String, dynamic>>()
          .map((detail) {
            final path = detail['path'];
            final field = path is List && path.isNotEmpty
                ? '${path.last}: '
                : '';
            return '$field${detail['message'] ?? 'Invalid value'}';
          })
          .join('\n');
      if (messages.isNotEmpty) return messages;
    }

    return data['error']?.toString() ?? 'Request failed';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
