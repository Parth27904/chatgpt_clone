// lib/services/cloudinary_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart'; // Import for lookupMimeType to get file's content type
import 'package:path/path.dart' as p; // Import path package for basename

class CloudinaryService {
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  Future<String?> uploadImage(File imageFile) async {
    print('CloudinaryService (Revamped): Starting image upload process...');
    print('CloudinaryService (Revamped): Provided image file path: ${imageFile.path}');

    // CRITICAL CHECK: Verify file existence before attempting upload
    if (!await imageFile.exists()) {
      print('CloudinaryService (Revamped): ERROR: Image file does not exist at path: ${imageFile.path}');
      return null;
    }
    print('CloudinaryService (Revamped): Image file confirmed to exist.');

    print('CloudinaryService (Revamped): Cloud Name: $_cloudName, Upload Preset: $_uploadPreset');

    try {
      final String uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
      print('CloudinaryService (Revamped): Target Upload URL: $uploadUrl');

      // --- REVAMPED PART: Read file bytes directly ---
      final List<int> imageBytes = await imageFile.readAsBytes();
      print('CloudinaryService (Revamped): Read ${imageBytes.length} bytes from image file.');

      // Determine MIME type based on file extension
      final String? mimeType = lookupMimeType(imageFile.path);
      print('CloudinaryService (Revamped): Detected MIME type: $mimeType');

      // Get filename from path for Cloudinary
      final String filename = p.basename(imageFile.path);
      print('CloudinaryService (Revamped): Original filename: $filename');

      // Create MultipartFile from bytes
      final http.MultipartFile file = http.MultipartFile.fromBytes(
        'file', // Field name for the file, REQUIRED by Cloudinary
        imageBytes,
        filename: filename, // Original filename
        contentType: mimeType != null ? MediaType.parse(mimeType) : null, // Explicit MIME type
      );
      print('CloudinaryService (Revamped): MultipartFile created from bytes.');
      // --- END REVAMPED PART ---

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(file); // Add the correctly created file part

      print('CloudinaryService (Revamped): Sending request to Cloudinary...');
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print('CloudinaryService (Revamped): Received response from Cloudinary. Status Code: ${streamedResponse.statusCode}');
      print('CloudinaryService (Revamped): Response Body: $responseBody');

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          print('CloudinaryService (Revamped): Image uploaded successfully. URL: $secureUrl');
          return secureUrl;
        } else {
          print('CloudinaryService (Revamped): Upload successful but "secure_url" is missing or empty in response.');
          throw Exception('Cloudinary upload successful but URL not returned.');
        }
      } else {
        print('CloudinaryService (Revamped): Upload failed with status code ${streamedResponse.statusCode}.');
        String errorMessage = 'Unknown Cloudinary error.';
        try {
          final errorData = jsonDecode(responseBody);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (_) {
          // Ignore JSON parsing errors if response body is not JSON
        }
        throw Exception('Failed to upload image to Cloudinary: $errorMessage (Status: ${streamedResponse.statusCode})');
      }
    } catch (e) {
      print('CloudinaryService (Revamped): Caught an unexpected exception during upload: $e');
      if (e is SocketException) {
        print('CloudinaryService (Revamped): SocketException: Check internet connection or firewall/proxy settings.');
      } else if (e is FormatException) {
        print('CloudinaryService (Revamped): FormatException: Response body is not valid JSON. Unexpected server response.');
      }
      return null;
    }
  }
}