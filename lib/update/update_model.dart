import 'dart:convert';

class UpdateModel {
  const UpdateModel({
    required this.version,
    required this.apkUrl,
    required this.changelog,
  });

  final String version;
  final String apkUrl;
  final String changelog;
  bool get forceUpdate => true;

  factory UpdateModel.fromRawJson(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid update payload');
    }
    return UpdateModel.fromJson(decoded);
  }

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final apkUrl = json['apk_url'];
    final changelog = json['changelog'];

    if (version is! String ||
        apkUrl is! String ||
        changelog is! String) {
      throw const FormatException('Missing or invalid update fields');
    }

    return UpdateModel(
      version: version,
      apkUrl: apkUrl,
      changelog: changelog,
    );
  }
}
