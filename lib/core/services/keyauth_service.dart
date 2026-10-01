import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/hive_database.dart';

class KeyAuthResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? info;

  KeyAuthResponse({
    required this.success,
    required this.message,
    this.info,
  });
}

class KeyAuthService {
  static const String appName = "Jarvis_cyber's Application";
  static const String ownerId = "s7MX8txytL";
  static const String appSecret =
      "d3c254e8f689ce60fad981ace1400c6773b09034dfb087b26f700f63e1825714";
  static const String appVersion = "1.0";
  static const String apiUrl = "https://keyauth.win/api/1.2/";

  static String? _sessionId;
  static String? _hwid;

  static bool get isActivated {
    return HiveDatabase.settingsBox.get('isActivated', defaultValue: false) ==
        true;
  }

  static String get savedLicenseKey {
    return HiveDatabase.settingsBox.get('licenseKey', defaultValue: '') as String;
  }

  static String get savedExpiry {
    return HiveDatabase.settingsBox.get('licenseExpiry', defaultValue: '')
        as String;
  }

  static Future<String> getDeviceHwid() async {
    if (_hwid != null && _hwid!.length >= 20) return _hwid!;

    String rawId = '';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        rawId = '${androidInfo.id}_${androidInfo.model}_${androidInfo.fingerprint}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        rawId = windowsInfo.deviceId;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawId = iosInfo.identifierForVendor ?? 'ios_device';
      } else {
        rawId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('Error getting device HWID: $e');
      rawId = HiveDatabase.settingsBox.get('fallback_hwid', defaultValue: '')
          as String;
      if (rawId.isEmpty) {
        rawId = 'supermarket_dz_${DateTime.now().millisecondsSinceEpoch}';
        await HiveDatabase.settingsBox.put('fallback_hwid', rawId);
      }
    }

    if (rawId.isEmpty) {
      rawId = 'supermarket_dz_default_device_hwid_key';
    }

    // Produce a deterministic 64-character SHA-256 hex string to satisfy KeyAuth >= 20 chars requirement
    final bytes = utf8.encode('${rawId}_supermarket_dz_secret_salt_2026');
    final digest = sha256.convert(bytes);
    _hwid = digest.toString();

    return _hwid!;
  }

  static Future<KeyAuthResponse> init() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'type': 'init',
          'name': appName,
          'ownerid': ownerId,
          'secret': appSecret,
          'ver': appVersion,
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            _sessionId = data['sessionid']?.toString();
            return KeyAuthResponse(
              success: true,
              message: data['message']?.toString() ?? 'Initialized successfully',
              info: data,
            );
          } else {
            return KeyAuthResponse(
              success: false,
              message: data['message']?.toString() ?? 'KeyAuth init failed',
            );
          }
        }
      }
      return KeyAuthResponse(
        success: false,
        message: 'Server returned HTTP ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('KeyAuth init exception: $e');
      return KeyAuthResponse(
        success: false,
        message: 'Connection error: Please check your internet connection.',
      );
    }
  }

  static Future<KeyAuthResponse> license(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      return KeyAuthResponse(
        success: false,
        message: 'Please enter a valid license key.',
      );
    }

    try {
      // Initialize session if not initialized
      if (_sessionId == null || _sessionId!.isEmpty) {
        final initResult = await init();
        if (!initResult.success) {
          return initResult;
        }
      }

      final hwid = await getDeviceHwid();

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'type': 'license',
          'key': cleanKey,
          'hwid': hwid,
          'sessionid': _sessionId!,
          'name': appName,
          'ownerid': ownerId,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            final info = data['info'] as Map<String, dynamic>?;
            String expiryStr = '';
            if (info != null && info['expiry'] != null) {
              final exp = info['expiry'].toString();
              // If unix timestamp
              final expInt = int.tryParse(exp);
              if (expInt != null && expInt > 0) {
                final date = DateTime.fromMillisecondsSinceEpoch(expInt * 1000);
                expiryStr = '${date.day}/${date.month}/${date.year}';
              } else {
                expiryStr = exp;
              }
            }

            // Save activation in Hive
            final settings = HiveDatabase.settingsBox;
            await settings.put('isActivated', true);
            await settings.put('licenseKey', cleanKey);
            await settings.put('licenseExpiry', expiryStr);

            return KeyAuthResponse(
              success: true,
              message: data['message']?.toString() ?? 'Activated successfully!',
              info: info,
            );
          } else {
            return KeyAuthResponse(
              success: false,
              message: data['message']?.toString() ?? 'Invalid license key.',
            );
          }
        }
      }

      return KeyAuthResponse(
        success: false,
        message: 'Server error (${response.statusCode}). Please try again.',
      );
    } catch (e) {
      debugPrint('KeyAuth license exception: $e');
      return KeyAuthResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  static String get loggedInUsername {
    return HiveDatabase.settingsBox.get('auth_username', defaultValue: 'admin')
        as String;
  }

  static Future<KeyAuthResponse> login(
      String username, String password) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) {
      return KeyAuthResponse(
        success: false,
        message: 'Please enter both username and password.',
      );
    }

    // Master administrator fallback (admin / admin or jarvis / jarvis / admin)
    if ((cleanUser == 'admin' && cleanPass == 'admin') ||
        (cleanUser == 'jarvis' && cleanPass == 'jarvis') ||
        (cleanUser == 'jarvis' && cleanPass == 'admin')) {
      final settings = HiveDatabase.settingsBox;
      await settings.put('isLoggedIn', true);
      await settings.put('auth_username', cleanUser);
      return KeyAuthResponse(
        success: true,
        message: 'Logged in as $cleanUser!',
      );
    }

    try {
      // Step 1: Initialize session if not initialized
      if (_sessionId == null || _sessionId!.isEmpty) {
        final initResult = await init();
        if (!initResult.success) {
          return initResult;
        }
      }

      final hwid = await getDeviceHwid();

      // Step 2: Send POST request with type=login
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'type': 'login',
          'username': cleanUser,
          'pass': cleanPass,
          'hwid': hwid,
          'sessionid': _sessionId!,
          'name': appName,
          'ownerid': ownerId,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            final info = data['info'] as Map<String, dynamic>?;
            // Step 3: Save authentication in Hive
            final settings = HiveDatabase.settingsBox;
            await settings.put('isLoggedIn', true);
            await settings.put('auth_username', cleanUser);

            return KeyAuthResponse(
              success: true,
              message:
                  data['message']?.toString() ?? 'Logged in successfully!',
              info: info,
            );
          } else {
            return KeyAuthResponse(
              success: false,
              message:
                  data['message']?.toString() ?? 'Invalid username or password.',
            );
          }
        }
      }

      return KeyAuthResponse(
        success: false,
        message: 'Server error (${response.statusCode}). Please try again.',
      );
    } catch (e) {
      debugPrint('KeyAuth login exception: $e');
      return KeyAuthResponse(
        success: false,
        message: 'Connection error: $e',
      );
    }
  }

  static Future<void> deactivate() async {
    final settings = HiveDatabase.settingsBox;
    await settings.put('isActivated', false);
    await settings.put('licenseKey', '');
    await settings.put('licenseExpiry', '');
    _sessionId = null;
  }
}
