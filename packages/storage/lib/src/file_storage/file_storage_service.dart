import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for managing file storage on the local file system.
///
/// Provides methods for reading, writing, and managing files
/// within the application's document directory. On web platforms,
/// operations are handled through browser APIs.
class FileStorageService {
  FileStorageService._();

  static FileStorageService? _instance;

  /// Returns the singleton instance.
  static FileStorageService get instance {
    _instance ??= FileStorageService._();
    return _instance!;
  }

  Directory? _appDirectory;

  /// Gets the application documents directory.
  Future<Directory> get appDirectory async {
    if (_appDirectory != null) return _appDirectory!;

    if (kIsWeb) {
      throw UnsupportedError(
        'Direct file system access is not available on web. '
        'Use IndexedDB or browser file APIs instead.',
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    _appDirectory = Directory(p.join(docsDir.path, 'FileUtility', 'files'));

    if (!await _appDirectory!.exists()) {
      await _appDirectory!.create(recursive: true);
    }

    return _appDirectory!;
  }

  /// Reads a text file and returns its contents.
  Future<String> readTextFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    return file.readAsString();
  }

  /// Writes text content to a file.
  Future<File> writeTextFile(String filePath, String content) async {
    final file = File(filePath);
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return file.writeAsString(content);
  }

  /// Reads a binary file and returns its bytes.
  Future<Uint8List> readBinaryFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    return file.readAsBytes();
  }

  /// Writes binary content to a file.
  Future<File> writeBinaryFile(String filePath, Uint8List bytes) async {
    final file = File(filePath);
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return file.writeAsBytes(bytes);
  }

  /// Copies a file to a new location.
  Future<File> copyFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    final destDir = File(destPath).parent;
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    return sourceFile.copy(destPath);
  }

  /// Moves a file to a new location.
  Future<File> moveFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    final destDir = File(destPath).parent;
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    return sourceFile.rename(destPath);
  }

  /// Deletes a file.
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns file metadata.
  Future<FileStat> getFileInfo(String filePath) async {
    return File(filePath).stat();
  }

  /// Lists files in a directory.
  Future<List<FileSystemEntity>> listDirectory(
    String dirPath, {
    bool recursive = false,
  }) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return [];
    }
    return directory.list(recursive: recursive).toList();
  }

  /// Creates a directory.
  Future<Directory> createDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    return directory.create(recursive: true);
  }

  /// Checks if a file exists.
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  /// Checks if a directory exists.
  Future<bool> directoryExists(String dirPath) async {
    return Directory(dirPath).exists();
  }

  /// Returns the file size in bytes.
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return 0;
    return file.length();
  }

  /// Saves content to the app's internal storage and returns the path.
  Future<String> saveToAppStorage(
    String fileName,
    String content, {
    String? subdirectory,
  }) async {
    final dir = await appDirectory;
    final targetDir = subdirectory != null
        ? Directory(p.join(dir.path, subdirectory))
        : dir;

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final filePath = p.join(targetDir.path, fileName);
    await File(filePath).writeAsString(content);
    return filePath;
  }
}
