import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SupportService {
  SupportService._();

  static final SupportService instance = SupportService._();

  static const String _baseUrl = 'https://ai-backend-aoab.onrender.com';

  /// Send a support message to the backend AI and return the reply text.
  ///
  /// This method includes the current user's Firebase ID token in the
  /// Authorization header as `Bearer <token>`.
  Future<String> askSupport(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    final candidatePaths = <String>[
      '/ai/support/ask',
      '/api/support/ask',
      '/support/ask',
    ];

    // First try with the current (possibly cached) ID token. The Firebase SDK
    // automatically refreshes expired tokens in most cases, but we also
    // handle 401/403 from the backend by forcing a refresh and retrying once.
    String? token = await user.getIdToken();
    token ??= await user.getIdToken(true);
    if (token == null) {
      throw StateError('Could not obtain ID token');
    }

    var tokenValue = token;

    // Debug: print the Firebase ID token so it can be used for backend tests.
    // Remove this in production if you do not want tokens in logs.
    // ignore: avoid_print
    print('FIREBASE_ID_TOKEN: $tokenValue');

    Exception? lastError;

    for (final path in candidatePaths) {
      final uri = Uri.parse('$_baseUrl$path');

      Future<http.Response> sendWithToken(String token) {
        return http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(<String, dynamic>{
            'message': message,
          }),
        );
      }

      http.Response response;
      try {
        response = await sendWithToken(tokenValue);
      } catch (e) {
        lastError = Exception('Support request failed ($path): $e');
        continue;
      }

      if (response.statusCode == 404) {
        lastError = Exception('Support API not found ($path): ${response.body}');
        continue;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        token = await user.getIdToken(true);
        if (token == null) {
          throw StateError('Could not refresh ID token');
        }
        tokenValue = token;
        response = await sendWithToken(tokenValue);
      }

      if (response.statusCode != 200) {
        lastError = Exception(
          'Support API error (${response.statusCode}) ($path): ${response.body}',
        );
        continue;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic replyField =
            decoded['reply'] ?? decoded['answer'] ?? decoded['message'];
        if (replyField != null && replyField.toString().trim().isNotEmpty) {
          return replyField.toString();
        }
      }

      return 'Support replied: ${response.body}';
    }

    throw lastError ?? Exception('Support API request failed');
  }
}
