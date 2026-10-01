import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  static const String _desktopClientId = String.fromEnvironment(
    'DESKTOP_CLIENT_ID',
    defaultValue: '',
  );
  static const String _desktopClientSecret = String.fromEnvironment(
    'DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );
  static const String _backupFileName = 'feapi_app_data.enc';
  static const String _refreshTokenKey = 'drive_refresh_token';
  static const _scopes = [drive.DriveApi.driveAppdataScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Penyimpanan sesi di RAM sebagai fallback utama saat runtime
  AutoRefreshingAuthClient? _desktopAuthClient;

  Future<bool> hasSession() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      if (_desktopAuthClient != null) return true;
      final savedToken = await _secureStorage.read(key: _refreshTokenKey);
      return savedToken != null;
    } else {
      return await _googleSignIn.isSignedIn();
    }
  }

  void _launchUrl(String url) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // 1. Cek sesi aktif di RAM terlebih dahulu
      if (_desktopAuthClient != null) {
        return drive.DriveApi(_desktopAuthClient!);
      }

      final clientId = ClientId(_desktopClientId, _desktopClientSecret);

      // 2. Cek token yang tersimpan di Secure Storage
      try {
        final savedRefreshToken = await _secureStorage.read(
          key: _refreshTokenKey,
        );

        if (savedRefreshToken != null) {
          final credentials = AccessCredentials(
            // Membuat token akses kedaluwarsa secara artifisial agar sistem langsung melakukan refresh
            AccessToken(
              'Bearer',
              'dummy_token',
              DateTime.now().toUtc().subtract(const Duration(days: 1)),
            ),
            savedRefreshToken,
            _scopes,
          );

          _desktopAuthClient = autoRefreshingClient(
            clientId,
            credentials,
            http.Client(),
          );
          return drive.DriveApi(_desktopAuthClient!);
        }
      } catch (e) {
        debugPrint('Gagal memuat sesi dari storage: $e');
      }

      // 3. Fallback: Buka browser untuk persetujuan pengguna jika RAM dan Storage kosong
      try {
        _desktopAuthClient = await clientViaUserConsent(clientId, _scopes, (
          String url,
        ) {
          _launchUrl(url);
        });

        // Simpan token otorisasi ke storage untuk sesi berikutnya
        final newRefreshToken = _desktopAuthClient?.credentials.refreshToken;
        if (newRefreshToken != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: newRefreshToken,
          );
        }

        return drive.DriveApi(_desktopAuthClient!);
      } catch (e) {
        debugPrint('Desktop Auth Error: $e');
        return null;
      }
    } else {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }

      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    }
  }

  Future<void> backupDatabase(String encryptedData) async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Gagal login ke akun Google');

    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );

    final driveFile = drive.File()..name = _backupFileName;
    final bytes = utf8.encode(encryptedData);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final existingFileId = fileList.files!.first.id!;
      await api.files.update(driveFile, existingFileId, uploadMedia: media);
    } else {
      driveFile.parents = ['appDataFolder'];
      await api.files.create(driveFile, uploadMedia: media);
    }
  }

  Future<String> restoreDatabase() async {
    final api = await _getDriveApi();
    if (api == null) throw Exception('Gagal login ke akun Google');

    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      throw Exception('Tidak ada file backup ditemukan di Google Drive');
    }

    final fileId = fileList.files!.first.id!;
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataStore = [];
    await for (final data in media.stream) {
      dataStore.addAll(data);
    }

    return utf8.decode(dataStore);
  }

  Future<void> logout() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _desktopAuthClient?.close();
      _desktopAuthClient = null;
      await _secureStorage.delete(key: _refreshTokenKey);
    } else {
      await _googleSignIn.signOut();
    }
  }
}
