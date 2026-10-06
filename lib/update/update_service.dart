import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_model.dart';

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const String _updateUrl = 'https://www.yooo.app/update.json';
  final http.Client _client;

  Future<UpdateModel?> checkForUpdate() async {
    try {
      final response = await _client.get(
        Uri.parse(_updateUrl),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final update = UpdateModel.fromRawJson(response.body);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isRemoteVersionNewer(update.version, currentVersion)) {
        return update;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> openUpdateUrl(String apkUrl) async {
    final uri = Uri.tryParse(apkUrl);
    if (uri == null) return false;

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  bool _isRemoteVersionNewer(String remote, String local) {
    final remoteParts = _parseVersion(remote);
    final localParts = _parseVersion(local);

    for (var i = 0; i < 3; i++) {
      if (remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    final cleaned = version.trim();
    final parts = cleaned.split('.');
    final normalized = <int>[0, 0, 0];

    for (var i = 0; i < 3 && i < parts.length; i++) {
      normalized[i] = int.tryParse(parts[i]) ?? 0;
    }
    return normalized;
  }
}
