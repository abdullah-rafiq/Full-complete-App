import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  static const String cloudName = 'dbwhvelwc';
  static const String uploadPreset = 'GharAssist';

  static const String _apiBase = 'https://api.cloudinary.com/v1_1';

  Future<CloudinaryUploadResult> uploadImage({
    required Uint8List bytes,
    required String folder,
    required String publicId,
    required String fileName,
  }) async {
   
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw StateError(
        'CloudinaryService is not configured. Set cloudName and uploadPreset.',
      );
    }

    final uri = Uri.parse('$_apiBase/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): $body',
      );
    }

    final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;

    final secureUrl = data['secure_url'] as String?;
    final publicIdResult = data['public_id'] as String?;

    if (secureUrl == null || publicIdResult == null) {
      throw Exception('Cloudinary response missing secure_url or public_id');
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId: publicIdResult,
    );
  }
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}
