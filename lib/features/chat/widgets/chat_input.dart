import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import '../../../core/theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(String)? onAttachment; // Callback for when a file is selected
  final Function(String)? onVoiceMessage; // Callback for voice recordings

  const ChatInput({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.onVoiceMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isComposing = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  String? _recordingPath;

  void _handleSubmitted(String text) {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    widget.onSend(text);
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final filePath = result.files.first.path;
                      if (filePath != null && widget.onAttachment != null) {
                        widget.onAttachment!(filePath);
                      }
                    }
                  },
                ),
                _AttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final filePath = result.files.first.path;
                      if (filePath != null && widget.onAttachment != null) {
                        widget.onAttachment!(filePath);
                      }
                    }
                  },
                ),
                _AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.any,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final filePath = result.files.first.path;
                      if (filePath != null && widget.onAttachment != null) {
                        widget.onAttachment!(filePath);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    // Request microphone permission
    final permission = await Permission.microphone.request();

    if (!permission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for voice recording',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Create a unique file path for the recording
      final directory = await getTemporaryDirectory();
      _recordingPath =
          '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      // Stop recording
      final path = await _audioRecorder.stop();

      // Stop timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });

      // Send the voice message if recording was successful
      if (path != null && widget.onVoiceMessage != null) {
        widget.onVoiceMessage!(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelRecording() async {
    if (!_isRecording) return;

    try {
      // Stop recording
      await _audioRecorder.stop();

      // Stop timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });

      // Optionally delete the canceled recording file
      // You can add file deletion logic here if needed
    } catch (e) {
      // Silently handle cancellation errors
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: AppTheme.secondaryBackground,
      child: SafeArea(
        child: Row(
          children: [
            if (!_isRecording)
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.accentColor),
                onPressed: _showAttachmentMenu,
              ),
            Expanded(
              child: _isRecording
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recording ${_formatDuration(_recordingDuration)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '← Swipe to cancel',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: _controller,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.isNotEmpty;
                        });
                      },
                      onSubmitted: _isComposing ? _handleSubmitted : null,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
            ),
            const SizedBox(width: 8),
            if (_isComposing)
              CircleAvatar(
                backgroundColor: AppTheme.accentColor,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _handleSubmitted(_controller.text),
                ),
              )
            else
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                onLongPressCancel: _cancelRecording,
                child: CircleAvatar(
                  backgroundColor: _isRecording
                      ? Colors.red
                      : AppTheme.accentColor.withValues(alpha: 0.2),
                  radius: 20,
                  child: Icon(
                    Icons.mic,
                    color: _isRecording ? Colors.white : AppTheme.accentColor,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for attachment menu options
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
        child: Icon(icon, color: AppTheme.accentColor),
      ),
      title: Text(
        label,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
