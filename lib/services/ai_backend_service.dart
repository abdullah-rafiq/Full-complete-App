import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiBackendService {
  AiBackendService._();

  static final AiBackendService instance = AiBackendService._();

  // Keep this in sync with the backend deployment used by SupportService.
  static const String _baseUrl = 'https://ai-backend-aoab.onrender.com';

  Future<Map<String, dynamic>> _postAuthedJson(
    String path,
    Map<String, dynamic> body,
  ) async {
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

    if (response.statusCode != 200) {
      throw Exception(
        'AI backend error (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'raw': decoded};
  }

  Future<Map<String, dynamic>> verifyCnic({
    required String cnicFrontUrl,
    required String cnicBackUrl,
    String? expectedName,
    String? expectedFatherName,
    String? expectedDob,
  }) async {
    final frontResp = await http.get(Uri.parse(cnicFrontUrl));
    if (frontResp.statusCode != 200) {
      throw Exception('Failed to download CNIC front image');
    }

    final backResp = await http.get(Uri.parse(cnicBackUrl));
    if (backResp.statusCode != 200) {
      throw Exception('Failed to download CNIC back image');
    }

    final String frontBase64 = base64Encode(frontResp.bodyBytes);
    final String backBase64 = base64Encode(backResp.bodyBytes);

    final Map<String, dynamic> payload = <String, dynamic>{
      'cnicFrontBase64': frontBase64,
      'cnicBackBase64': backBase64,
    };

    if (expectedName != null && expectedName.isNotEmpty) {
      payload['expectedName'] = expectedName;
    }
    if (expectedFatherName != null && expectedFatherName.isNotEmpty) {
      payload['expectedFatherName'] = expectedFatherName;
    }
    if (expectedDob != null && expectedDob.isNotEmpty) {
      payload['expectedDob'] = expectedDob;
    }

    return _postAuthedJson('/api/vision/verify-cnic', payload);
  }

  Future<Map<String, dynamic>> verifyFace({
    required String cnicImageUrl,
    required String selfieImageUrl,
  }) async {
    final cnicResp = await http.get(Uri.parse(cnicImageUrl));
    if (cnicResp.statusCode != 200) {
      throw Exception('Failed to download CNIC image');
    }

    final selfieResp = await http.get(Uri.parse(selfieImageUrl));
    if (selfieResp.statusCode != 200) {
      throw Exception('Failed to download selfie image');
    }

    final String cnicBase64 = base64Encode(cnicResp.bodyBytes);
    final String selfieBase64 = base64Encode(selfieResp.bodyBytes);

    final Map<String, dynamic> payload = <String, dynamic>{
      'cnicImage': cnicBase64,
      'selfieImage': selfieBase64,
    };

    return _postAuthedJson('/api/kyc/face', payload);
  }

  Future<Map<String, dynamic>> verifyShop({
    required String shopImageUrl,
  }) async {
    final shopResp = await http.get(Uri.parse(shopImageUrl));
    if (shopResp.statusCode != 200) {
      throw Exception('Failed to download shop image');
    }

    final String shopBase64 = base64Encode(shopResp.bodyBytes);

    final Map<String, dynamic> payload = <String, dynamic>{
      'shopImage': shopBase64,
    };

    return _postAuthedJson('/api/kyc/shop', payload);
  }

  Future<Map<String, dynamic>> speechToText(Uint8List audioBytes) {
    final String audioBase64 = base64Encode(audioBytes);
    return _postAuthedJson('/api/speech-to-text', <String, dynamic>{
      'audioBase64': audioBase64,
    });
  }

  /// Translate arbitrary text into English using the AI backend.
  ///
  /// This is useful for voice queries where the user may speak in
  /// Urdu or Roman Urdu but the search UI expects English keywords.
  /// If translation fails for any reason, the original [text] is
  /// returned so the caller can still proceed.
  Future<String> translateToEnglish(String text) async {
    final Map<String, dynamic> resp = await _postAuthedJson(
      '/ai/text/translate',
      <String, dynamic>{'text': text, 'targetLang': 'en'},
    );

    final dynamic translationField = resp['translation'];
    if (translationField is String && translationField.trim().isNotEmpty) {
      return translationField;
    }

    return text;
  }

  /// Analyze sentiment of a single text using the AI backend.
  ///
  /// The backend is expected to return at least a `sentiment` field
  /// ("positive" | "neutral" | "negative" | "unknown") and an
  /// optional `confidence` field in [0, 1]. The raw JSON map is
  /// returned to the caller for interpretation.
  Future<Map<String, dynamic>> analyzeSentiment(String text) {
    return _postAuthedJson('/ai/text/sentiment', <String, dynamic>{
      'text': text,
    });
  }
}
