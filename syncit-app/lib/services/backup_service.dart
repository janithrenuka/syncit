import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  Future<bool> _requestStoragePermission() async {
    // FilePicker handles contextual permissions on modern Android versions (11+).
    // For legacy support, you could add standard storage permission checks here,
    // but MANAGE_EXTERNAL_STORAGE is strictly avoided.
    return true;
  }

  Future<File?> _createBackupZip() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final suppDir = await getApplicationSupportDirectory();

      // 1. Resolve Hive's actual path by opening a temporary box
      // This is crucial because initFlutter() path choice can vary between platform versions.
      String? hivePath;
      try {
        final box = await Hive.openBox('backup_diagnostic_box');
        hivePath = box.path;
        await box.close();
        debugPrint('Backup: Resolved Hive path: $hivePath');
      } catch (e) {
        debugPrint('Backup: Could not resolve Hive path via box: $e');
      }

      final tempDir = await getTemporaryDirectory();
      final zipFilePath = '${tempDir.path}/SyncitBackup.zip';
      final zipFile = File(zipFilePath);
      if (await zipFile.exists()) await zipFile.delete();

      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFilePath);

      // Use a Map to keep track of unique directories to scan
      final Map<String, String> searchPaths = {
        'DOCS': docDir.path,
        'SUPP': suppDir.path,
      };

      if (hivePath != null) {
        // If it's a file path, get the directory
        final hiveDir = File(hivePath).parent.path;
        searchPaths['HIVE'] = hiveDir;
      }

      // Add parent of DOCS as a last resort "ROOT" to catch everything
      try {
        searchPaths['ROOT'] = docDir.parent.path;
      } catch (_) {}

      final Set<String> addedFiles = {};

      for (var entry in searchPaths.entries) {
        final prefix = entry.key;
        final dirPath = entry.value;
        final dir = Directory(dirPath);

        if (await dir.exists()) {
          debugPrint('Backup: Scanning $prefix: $dirPath');
          final List<FileSystemEntity> entities = await dir
              .list(recursive: true)
              .toList();
          for (var entity in entities) {
            if (entity is File) {
              final path = entity.path;
              if (path == zipFilePath || addedFiles.contains(path)) continue;

              // Filter: Only include data-like files or attachments
              // We want to avoid zipping cache, libs, or the zip itself
              final name = path.toLowerCase();
              bool isData =
                  name.endsWith('.hive') ||
                  name.endsWith('.lock') ||
                  name.endsWith('.binary') ||
                  path.contains('syncit_attachments');

              if (isData) {
                String relativePath = path.substring(dirPath.length);
                if (relativePath.startsWith('/') ||
                    relativePath.startsWith('\\')) {
                  relativePath = relativePath.substring(1);
                }

                final zipEntryName = '$prefix/$relativePath';
                debugPrint('Backup: Adding $zipEntryName');
                await zipEncoder.addFile(entity, zipEntryName);
                addedFiles.add(path);
              }
            }
          }
        }
      }

      zipEncoder.close();
      return zipFile;
    } catch (e) {
      debugPrint('Error creating backup zip: $e');
      return null;
    }
  }

  Future<bool> backupToLocal() async {
    try {
      if (!await _requestStoragePermission()) {
        debugPrint('Storage permission denied');
        return false;
      }

      // 1. CREATE ZIP FIRST (it needs Hive to be open to resolve path if using box.path)
      // Actually, resolve path BEFORE closing Hive.
      final zipFile = await _createBackupZip();
      if (zipFile == null) return false;

      // 2. Proactively close Hive after discovery
      await Hive.close();

      String? outputFile;
      if (Platform.isAndroid || Platform.isIOS) {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select folder to save Backup Bundle',
        );
        if (selectedDirectory != null) {
          outputFile =
              '$selectedDirectory/SyncitBackup_${DateTime.now().millisecondsSinceEpoch}.zip';
        }
      } else {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup Bundle',
          fileName: 'SyncitBackup_${DateTime.now().millisecondsSinceEpoch}.zip',
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
      }

      if (outputFile == null) return false;

      await zipFile.copy(outputFile);
      debugPrint('Backup: Bundle saved to $outputFile');
      return true;
    } catch (e) {
      debugPrint('Error backing up: $e');
      return false;
    }
  }

  Future<bool> restoreFromLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final docDir = await getApplicationDocumentsDirectory();
      final suppDir = await getApplicationSupportDirectory();

      debugPrint('Restore: Closing Hive before wipe...');
      await Hive.close();

      // Clean up both directories
      for (var dir in [docDir, suppDir]) {
        if (await dir.exists()) {
          final entities = await dir.list(recursive: true).toList();
          for (var entity in entities) {
            if (entity is File) await entity.delete();
          }
        }
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final archiveFile in archive) {
        final name = archiveFile.name;
        String? targetPath;

        // Restore based on prefix
        if (name.startsWith('DOCS/')) {
          targetPath = '${docDir.path}/${name.substring(5)}';
        } else if (name.startsWith('SUPP/')) {
          targetPath = '${suppDir.path}/${name.substring(5)}';
        } else if (name.startsWith('HIVE/')) {
          // If HIVE was resolved separately, restore it to Documents (Standard Hive location)
          targetPath = '${docDir.path}/${name.substring(5)}';
        } else if (name.startsWith('ROOT/')) {
          targetPath = '${docDir.parent.path}/${name.substring(5)}';
        }

        if (targetPath != null) {
          if (archiveFile.isFile) {
            final data = archiveFile.content as List<int>;
            File(targetPath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
            debugPrint('Restore: Extracted $targetPath');
          } else {
            Directory(targetPath).createSync(recursive: true);
          }
        }
      }

      await Hive.initFlutter();
      debugPrint('Restore: Hive re-initialized.');
      return true;
    } catch (e) {
      debugPrint('Error restoring from local: $e');
      return false;
    }
  }
}
