import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../settings/settings_page.dart';

class PhotosStep extends StatefulWidget {
  const PhotosStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<PhotosStep> {
  late List<String> _images;
  final Map<String, String> _localPreviewPaths = {};

  @override
  void initState() {
    super.initState();
    _images = _normalizeImages(widget.initialData['images']);
  }

  void _update() {
    widget.onChanged({'images': _images});
  }

  List<String> _normalizeImages(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is String) {
      final value = raw.trim();
      if (value.isEmpty) return <String>[];
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
        }
      } catch (_) {}
      return <String>[value];
    }
    return <String>[];
  }

  bool _isImagePath(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
  }

  Future<bool> _requestFilePermission() async {
    // FilePicker uses Android's document picker, so explicit storage permission
    // is typically not required on modern Android versions.
    if (Platform.isAndroid) return true;
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> _pickFileOrImage() async {
    final allowed = await _requestFilePermission();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File permission is required to upload photos/files.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
      ],
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return;
    if (_images.length >= 6) return;

    final localToken = 'local_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _images.add(localToken);
      _localPreviewPaths[localToken] = path;
    });

    final uploadedName = await _uploadImageToServer(path);
    if (!mounted) return;

    if (uploadedName == null || uploadedName.trim().isEmpty) {
      setState(() {
        _localPreviewPaths.remove(localToken);
        _images.remove(localToken);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Please try again.')),
      );
      return;
    }

    setState(() {
      final index = _images.indexOf(localToken);
      if (index != -1) {
        _images[index] = uploadedName;
      } else if (_images.length < 6) {
        _images.add(uploadedName);
      }
      _localPreviewPaths[uploadedName] = path;
      _localPreviewPaths.remove(localToken);
    });
    _update();
  }

  Future<String?> _uploadImageToServer(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;

    final candidateEndpoints = <String>[
      '${ApiEndpoints.baseUrl}/user/profile/upload-photo',
    ];

    for (final endpoint in candidateEndpoints) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(endpoint));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
        request.files.add(await http.MultipartFile.fromPath('photo', imagePath));

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final dynamic parsed = response.body.isNotEmpty ? json.decode(response.body) : null;
        if (parsed is Map<String, dynamic>) {
          final extracted = _extractImageNameFromResponse(parsed);
          if (extracted != null && extracted.trim().isNotEmpty) {
            return extracted.trim();
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String? _extractImageNameFromResponse(Map<String, dynamic> body) {
    final candidates = <dynamic>[
      body['image'],
      body['filename'],
      body['file_name'],
      body['name'],
      body['path'],
      body['url'],
      (body['data'] is Map ? body['data']['image'] : null),
      (body['data'] is Map ? body['data']['filename'] : null),
      (body['data'] is Map ? body['data']['file_name'] : null),
      (body['data'] is Map ? body['data']['name'] : null),
      (body['data'] is Map ? body['data']['path'] : null),
      (body['data'] is Map ? body['data']['url'] : null),
    ];

    for (final value in candidates) {
      if (value == null) continue;
      final raw = value.toString().trim();
      if (raw.isEmpty) continue;
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        return raw;
      }
      return raw.split('/').last;
    }
    return null;
  }

  String _resolveImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return raw;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final origin = Uri.parse(ApiEndpoints.baseUrl).origin;
    return '$origin/images/users/$raw';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          const Text('Add clear photos of yourself to attract more profile views.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final hasImage = index < _images.length;
              return InkWell(
                onTap: () {
                  if (!hasImage) {
                    _pickFileOrImage();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    image: hasImage && _isImagePath(_images[index])
                        ? DecorationImage(
                            image: _localPreviewPaths.containsKey(_images[index])
                                ? FileImage(File(_localPreviewPaths[_images[index]]!))
                                : NetworkImage(_resolveImageUrl(_images[index])) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasImage
                    ? Stack(
                        children: [
                          if (!_isImagePath(_images[index]))
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.insert_drive_file_rounded, color: Colors.blueGrey),
                                    const SizedBox(height: 4),
                                    Text(
                                      _images[index].split(Platform.pathSeparator).last,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _localPreviewPaths.remove(_images[index]);
                                  _images.removeAt(index);
                                });
                                _update();
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
