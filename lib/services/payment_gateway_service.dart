import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PaymentGatewayService {
  PaymentGatewayService._();

  static final PaymentGatewayService instance = PaymentGatewayService._();

  static const String _baseUrl =
      String.fromEnvironment(
        'PAYMENT_BACKEND_URL',
        defaultValue: 'https://ai-backend-aoab.onrender.com',
      );

  Future<Map<String, dynamic>> _postAuthedJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (_baseUrl.trim().isEmpty) {
      throw StateError('PAYMENT_BACKEND_URL is not configured');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }

    final uri = Uri.parse('$_baseUrl$path');

    Future<http.Response> sendWithToken(String token) {
      return http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    }

    String? token = await user.getIdToken();
    token ??= await user.getIdToken(true);
    if (token == null) {
      throw StateError('Could not obtain ID token');
    }

    http.Response response = await sendWithToken(token);

    if (response.statusCode == 401 || response.statusCode == 403) {
      token = await user.getIdToken(true);
      if (token == null) {
        throw StateError('Could not refresh ID token');
      }
      response = await sendWithToken(token);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Payment backend error (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'raw': decoded};
  }

  Future<Uri> createCardLinkUrl() async {
    final resp = await _postAuthedJson(
      '/api/payments/card/link',
      <String, dynamic>{},
    );

    final dynamic urlRaw = resp['url'];
    if (urlRaw is! String || urlRaw.trim().isEmpty) {
      throw Exception('Payment backend did not return a valid url');
    }

    return Uri.parse(urlRaw);
  }
}
