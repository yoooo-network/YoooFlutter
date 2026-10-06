import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'settings/settings_page.dart'; // To access ApiEndpoints.baseUrl

enum ContactsSyncStatus {
  success,
  permissionDenied,
  missingToken,
  unauthorized,
  networkError,
  serverError,
}

class ContactsSyncResult {
  const ContactsSyncResult(this.status, {this.message});

  final ContactsSyncStatus status;
  final String? message;

  bool get isSuccess => status == ContactsSyncStatus.success;
}

Future<ContactsSyncResult> syncContactsToServer({bool skipPermissionCheck = false}) async {
  try {
    if (!skipPermissionCheck && !await FlutterContacts.requestPermission()) {
      debugPrint('Contacts permission denied');
      return const ContactsSyncResult(ContactsSyncStatus.permissionDenied);
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final contactsJson = contacts
        .map(
          (c) => {
            'id': c.id,
            'displayName': c.displayName,
            'phones': c.phones
                .map((p) => {'number': p.number, 'label': p.label.toString()})
                .toList(),
            'emails': c.emails
                .map((e) => {'address': e.address, 'label': e.label.toString()})
                .toList(),
          },
        )
        .toList();

    final jsonString = json.encode(contactsJson);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/contacts.json');
    await file.writeAsString(jsonString);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token')?.trim();
    if (token == null || token.isEmpty) {
      debugPrint('Cannot upload contacts: auth token missing');
      return const ContactsSyncResult(ContactsSyncStatus.missingToken);
    }

    final endpoints = <String>[
      '${ApiEndpoints.baseUrl}/upload-contacts',
      '${ApiEndpoints.baseUrl}/user/upload-contacts',
    ];

    http.Response? response;
    bool allAttemptsWere404 = true;
    for (final endpoint in endpoints) {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('contacts_file', file.path),
      );

      final streamedResponse = await request.send();
      final attempted = await http.Response.fromStream(streamedResponse);
      response = attempted;

      if (attempted.statusCode != 404) {
        allAttemptsWere404 = false;
        break;
      }
    }

    if (response == null) {
      return const ContactsSyncResult(
        ContactsSyncStatus.serverError,
        message: 'Unable to reach contacts upload endpoint',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('Contacts uploaded successfully');
      return const ContactsSyncResult(ContactsSyncStatus.success);
    }

    if (response.statusCode == 401) {
      debugPrint('Failed to upload contacts: unauthorized token');
      return const ContactsSyncResult(ContactsSyncStatus.unauthorized);
    }

    if (allAttemptsWere404) {
      debugPrint('Failed to upload contacts: upload endpoint not found (404)');
      return const ContactsSyncResult(
        ContactsSyncStatus.serverError,
        message: 'Contacts upload endpoint not found (404). Please verify server route.',
      );
    }

    debugPrint('Failed to upload contacts: ${response.statusCode} ${response.body}');
    String serverMessage = 'Server error: ${response.statusCode}';
    if (response.body.isNotEmpty) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            serverMessage = message;
          }
        }
      } catch (_) {
        // Ignore invalid JSON body and keep fallback message.
      }
    }
    return ContactsSyncResult(
      ContactsSyncStatus.serverError,
      message: serverMessage,
    );
  } on SocketException catch (e) {
    debugPrint('Contacts sync network error: $e');
    return const ContactsSyncResult(
      ContactsSyncStatus.networkError,
      message: 'No internet connection',
    );
  } catch (e) {
    debugPrint('Contacts sync error: $e');
    return ContactsSyncResult(
      ContactsSyncStatus.serverError,
      message: 'Unexpected error: $e',
    );
  }
}
