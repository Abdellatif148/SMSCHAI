import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxDocumentSize = 20 * 1024 * 1024; // 20MB

  /// Capture photo from camera
  Future<File?> captureFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      debugPrint('Error capturing from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// Capture video from camera
  Future<File?> captureVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      debugPrint('Error capturing video: $e');
      return null;
    }
  }

  /// Pick document file
  Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final filePath = result.files.first.path;
      if (filePath == null) return null;

      return File(filePath);
    } catch (e) {
      debugPrint('Error picking document: $e');
      return null;
    }
  }

  /// Compress image file
  Future<File> compressImage(File imageFile) async {
    try {
      final int fileSize = await imageFile.length();

      // If file is already small enough, return as is
      if (fileSize < 1024 * 1024) {
        // Less than 1MB
        return imageFile;
      }

      // Generate output path
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress the image
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            imageFile.absolute.path,
            targetPath,
            quality: 70,
            minWidth: 1920,
            minHeight: 1080,
            format: CompressFormat.jpeg,
          );

      if (compressedFile == null) {
        debugPrint('Compression failed, returning original file');
        return imageFile;
      }

      final compressedSize = await File(compressedFile.path).length();
      debugPrint(
        'Image compressed: ${fileSize / 1024}KB → ${compressedSize / 1024}KB',
      );

      return File(compressedFile.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original on error
    }
  }

  /// Compress video file
  Future<File?> compressVideo(File videoFile) async {
    try {
      final int fileSize = await videoFile.length();

      // If file is already small enough, return as is
      if (fileSize < 5 * 1024 * 1024) {
        // Less than 5MB
        return videoFile;
      }

      debugPrint('Compressing video...');
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        debugPrint('Video compression failed, returning original file');
        return videoFile;
      }

      final compressedSize = await mediaInfo.file!.length();
      debugPrint(
        'Video compressed: ${fileSize / 1024 / 1024}MB → ${compressedSize / 1024 / 1024}MB',
      );

      return mediaInfo.file;
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return videoFile; // Return original on error
    }
  }

  /// Get MIME type of a file
  String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Validate file size based on type
  Future<bool> validateFileSize(File file, String fileType) async {
    try {
      final int fileSize = await file.length();

      if (fileType.startsWith('image/')) {
        return fileSize <= maxImageSize;
      } else if (fileType.startsWith('video/')) {
        return fileSize <= maxVideoSize;
      } else {
        return fileSize <= maxDocumentSize;
      }
    } catch (e) {
      debugPrint('Error validating file size: $e');
      return false;
    }
  }

  /// Get human-readable file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Process media file - compress and validate
  Future<Map<String, dynamic>?> processMediaFile(File file) async {
    try {
      final String? mimeType = getMimeType(file.path);
      if (mimeType == null) {
        return {'error': 'Could not determine file type'};
      }

      File processedFile = file;

      // Compress based on type
      if (mimeType.startsWith('image/')) {
        processedFile = await compressImage(file);
      } else if (mimeType.startsWith('video/')) {
        final compressed = await compressVideo(file);
        if (compressed != null) processedFile = compressed;
      }

      // Validate size after compression
      final bool isValid = await validateFileSize(processedFile, mimeType);
      if (!isValid) {
        final fileSize = await processedFile.length();
        return {
          'error':
              'File too large: ${formatFileSize(fileSize)}. Maximum allowed: ${formatFileSize(_getMaxSize(mimeType))}',
        };
      }

      return {
        'file': processedFile,
        'mimeType': mimeType,
        'size': await processedFile.length(),
      };
    } catch (e) {
      return {'error': 'Error processing file: $e'};
    }
  }

  int _getMaxSize(String mimeType) {
    if (mimeType.startsWith('image/')) return maxImageSize;
    if (mimeType.startsWith('video/')) return maxVideoSize;
    return maxDocumentSize;
  }
}
