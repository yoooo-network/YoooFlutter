import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../settings/settings_page.dart';

class VerifyStep extends StatefulWidget {
  const VerifyStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends State<VerifyStep> {
  String? _liveSelfieFileName;
  String? _idDocumentFileName;
  bool _isUploadingLiveSelfie = false;
  bool _isUploadingIdDocument = false;

  @override
  void initState() {
    super.initState();
    _liveSelfieFileName = _readExistingFileName(
      widget.initialData,
      'live_selfie',
      fallbackKey: 'live_selfie_file',
    );
    _idDocumentFileName = _readExistingFileName(
      widget.initialData,
      'id_verification',
      fallbackKey: 'id_document_file',
    );
  }

  String? _readExistingFileName(
    Map<String, dynamic> data,
    String primaryKey, {
    String? fallbackKey,
  }) {
    final direct = data[primaryKey];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    if (fallbackKey != null) {
      final fallback = data[fallbackKey];
      if (fallback != null && fallback.toString().trim().isNotEmpty) {
        return fallback.toString().trim();
      }
    }
    return null;
  }

  Future<bool> _requestFilePermission() async {
    if (Platform.isAndroid) return true;
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _pickAndUploadVerification({
    required bool forLiveSelfie,
  }) async {
    final allowed = await _requestFilePermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File permission is required to upload verification images.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty) return;

    setState(() {
      if (forLiveSelfie) {
        _isUploadingLiveSelfie = true;
      } else {
        _isUploadingIdDocument = true;
      }
    });

    final uploaded = await _uploadVerificationFile(
      imagePath: path,
      fieldName: forLiveSelfie ? 'live_selfie_file' : 'id_document_file',
    );

    if (!mounted) return;
    setState(() {
      if (forLiveSelfie) {
        _isUploadingLiveSelfie = false;
      } else {
        _isUploadingIdDocument = false;
      }
    });

    if (uploaded == null || uploaded.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification upload failed. Please try again.')),
      );
      return;
    }

    setState(() {
      if (forLiveSelfie) {
        _liveSelfieFileName = uploaded.trim();
      } else {
        _idDocumentFileName = uploaded.trim();
      }
    });

    widget.onChanged({
      'live_selfie': _liveSelfieFileName,
      'id_verification': _idDocumentFileName,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(forLiveSelfie ? 'Live selfie uploaded.' : 'ID document uploaded.'),
      ),
    );
  }

  Future<String?> _uploadVerificationFile({
    required String imagePath,
    required String fieldName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiEndpoints.baseUrl}/user/profile/upload-verification-files'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath(fieldName, imagePath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic parsed =
          response.body.isNotEmpty ? json.decode(response.body) : null;
      if (parsed is! Map<String, dynamic>) return null;

      final data = parsed['data'];
      if (data is! Map<String, dynamic>) return null;
      final files = data['files'];
      if (files is! Map<String, dynamic>) return null;

      final apiKey = fieldName == 'live_selfie_file'
          ? 'live_selfie'
          : 'id_verification';
      final value = files[apiKey];
      if (value == null) return null;
      final extracted = value.toString().trim();
      if (extracted.isEmpty) return null;
      return extracted;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.initialData['is_verified'] == true || widget.initialData['is_verified'] == 1 || widget.initialData['is_verified'] == "1";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.verified_user_outlined,
            size: 80,
            color: isVerified ? Colors.blue : Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            isVerified ? 'You are Verified!' : 'Verify Your Profile',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isVerified 
              ? 'Your identity has been confirmed. You have full access to all features.'
              : 'To ensure the safety of our community, we require all users to verify their identity.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 32),
            _buildVerificationOption(
              Icons.camera_alt_outlined,
              'Live Selfie',
              'Take a photo of yourself in real-time.',
              fileName: _liveSelfieFileName,
              isUploading: _isUploadingLiveSelfie,
              onTap: () => _pickAndUploadVerification(forLiveSelfie: true),
            ),
            const SizedBox(height: 16),
            _buildVerificationOption(
              Icons.badge_outlined,
              'ID Verification',
              'Upload a photo of your government-issued ID.',
              fileName: _idDocumentFileName,
              isUploading: _isUploadingIdDocument,
              onTap: () => _pickAndUploadVerification(forLiveSelfie: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationOption(
    IconData icon,
    String title,
    String subtitle, {
    required String? fileName,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  if (fileName != null && fileName.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Uploaded: $fileName',
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                fileName != null && fileName.trim().isNotEmpty
                    ? Icons.check_circle
                    : Icons.chevron_right,
                color: fileName != null && fileName.trim().isNotEmpty
                    ? Colors.green
                    : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
