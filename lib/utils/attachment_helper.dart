import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;

class AttachmentHelper {
  static final AttachmentHelper _instance = AttachmentHelper._internal();
  factory AttachmentHelper() => _instance;
  AttachmentHelper._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  // ===== Image Picker =====

  Future<File?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===== Video Picker =====

  Future<File?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ===== File Picker =====

  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ===== Camera =====

  Future<File?> takePhoto() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // You would typically navigate to a camera screen here
      // For this helper, we're just providing the camera instance
      // The actual implementation would be in the UI layer
      return null; // Placeholder - implement camera screen navigation
    } catch (e) {
      return null;
    }
  }

  Future<File?> recordVideo() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // Similar to takePhoto, navigate to a video recording screen
      return null; // Placeholder - implement video recording screen navigation
    } catch (e) {
      return null;
    }
  }

  // ===== Voice Recording =====

  Future<bool> startVoiceRecording() async {
    try {
      if (_isRecording) return false;

      // Check and request permission
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = path_lib.join(tempDir.path, 'voice_$timestamp.m4a');

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<File?> stopVoiceRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        return File(path);
      }
      return null;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  Future<void> cancelVoiceRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.cancel();
        _isRecording = false;
      }
    } catch (e) {
      _isRecording = false;
    }
  }

  bool get isRecording => _isRecording;

  Future<int> getRecordingDuration() async {
    // This would require additional implementation
    // You might need to track the start time yourself
    return 0;
  }

  // ===== File Type Detection =====

  static String getMediaType(String filePath) {
    final extension = path_lib.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
      case '.bmp':
        return 'image';
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.webm':
        return 'video';
      case '.mp3':
      case '.m4a':
      case '.aac':
      case '.wav':
      case '.ogg':
        return 'audio';
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.xls':
      case '.xlsx':
      case '.ppt':
      case '.pptx':
      case '.txt':
        return 'file';
      default:
        return 'file';
    }
  }

  static String getFileExtension(String filePath) {
    return path_lib.extension(filePath);
  }

  static String getFileName(String filePath) {
    return path_lib.basename(filePath);
  }

  // ===== File Size Validation =====

  static Future<bool> isFileSizeValid(File file, {int maxSizeMB = 100}) async {
    try {
      final fileSize = await file.length();
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      return fileSize <= maxSizeBytes;
    } catch (e) {
      return false;
    }
  }

  static Future<double> getFileSizeMB(File file) async {
    try {
      final fileSize = await file.length();
      return fileSize / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }

  // ===== Cleanup =====

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _audioRecorder.cancel();
      }
      await _audioRecorder.dispose();
    } catch (e) {
      // Silently fail
    }
  }
}
