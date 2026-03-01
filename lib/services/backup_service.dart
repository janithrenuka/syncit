import 'dart:convert';
import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncit/services/auth_service.dart';
import 'package:syncit/services/storage_service.dart';

class BackupService {
  final AuthService _authService;
  final StorageService _storageService;

  BackupService(this._authService, this._storageService);

  static const String _backupFileName = 'reminde_me_backup.json';

  // --- Local Backup ---

  Future<String> createLocalBackup() async {
    try {
      final jsonList = _storageService.exportToJson();
      final jsonString = jsonEncode(jsonList);

      // Save to Downloads folder (Android) or Documents (iOS)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$_backupFileName');
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to create local backup: $e');
    }
  }

  Future<void> restoreFromLocalBackup(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Backup file not found at $path');
      }
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List;
      await _storageService.importFromJson(jsonList);
    } catch (e) {
      throw Exception('Failed to restore from local backup: $e');
    }
  }

  // --- Google Drive Backup ---

  Future<void> uploadToDrive() async {
    final client = await _authService.googleSignIn.authenticatedClient();
    if (client == null) throw Exception('User not signed in');

    final driveApi = drive.DriveApi(client);
    final jsonList = _storageService.exportToJson();
    final jsonString = jsonEncode(jsonList);

    // Create a temporary file to upload
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$_backupFileName');
    await tempFile.writeAsString(jsonString);

    // Search for existing backup file
    final fileList = await driveApi.files.list(
      q: "name = '$_backupFileName' and 'appDataFolder' in parents",
      spaces: 'appDataFolder',
    );

    final media = drive.Media(tempFile.openRead(), tempFile.lengthSync());

    if (fileList.files?.isNotEmpty ?? false) {
      // Update existing file
      final fileId = fileList.files!.first.id!;
      await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
    } else {
      // Create new file
      await driveApi.files.create(
        drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'],
        uploadMedia: media,
      );
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    try {
      final client = await _authService.googleSignIn.authenticatedClient();
      if (client == null) return null;

      final driveApi = drive.DriveApi(client);
      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
        $fields: "files(id, modifiedTime)",
      );

      if (fileList.files?.isNotEmpty ?? false) {
        return fileList.files!.first.modifiedTime;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> restoreFromDrive() async {
    final client = await _authService.googleSignIn.authenticatedClient();
    if (client == null) throw Exception('User not signed in');

    final driveApi = drive.DriveApi(client);
    final fileList = await driveApi.files.list(
      q: "name = '$_backupFileName' and 'appDataFolder' in parents",
      spaces: 'appDataFolder',
    );

    if (fileList.files?.isEmpty ?? true) {
      throw Exception('No backup found on Drive');
    }

    final fileId = fileList.files!.first.id!;
    final drive.Media file =
        await driveApi.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final jsonString = await utf8.decodeStream(file.stream);
    final jsonList = jsonDecode(jsonString) as List;

    await _storageService.importFromJson(jsonList);
  }
}
