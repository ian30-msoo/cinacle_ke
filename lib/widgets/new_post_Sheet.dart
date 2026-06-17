import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';

class NewPostSheet extends StatefulWidget {
  final LetsTalkService service;
  final User user;

  const NewPostSheet({super.key, required this.service, required this.user});

  @override
  State<NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<NewPostSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _selectedTopic = 'Government';
  bool _isAnonymous = false;
  bool _submitting = false;

  File? _mediaFile; // mobile only
  Uint8List? _mediaBytes; // web only
  String? _mediaType; // 'image' or 'video'
  VideoPlayerController? _videoCtrl;

  static const _topics = [
    'Government',
    'Education',
    'Media',
    'Religion',
    'Arts & Culture',
  ];

  static const _tagIcons = <String, String>{
    'Government': 'bank',
    'Education': 'school',
    'Media': 'tv',
    'Religion': 'church',
    'Arts & Culture': 'mountain',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // MEDIA PICKING
  // ─────────────────────────────────────────────

  Future<void> _pickMedia(ImageSource source, String type) async {
    final picker = ImagePicker();
    XFile? picked;

    if (type == 'image') {
      picked = await picker.pickImage(source: source, imageQuality: 80);
    } else {
      picked = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
    }

    if (picked == null) return;

    _videoCtrl?.dispose();
    File? file;
    Uint8List? bytes;
    VideoPlayerController? newCtrl;

    if (kIsWeb) {
      bytes = await picked.readAsBytes();
    } else {
      file = File(picked.path);
      if (type == 'video') {
        newCtrl = VideoPlayerController.file(file);
        await newCtrl.initialize();
      }
    }

    setState(() {
      _mediaFile = file;
      _mediaBytes = bytes;
      _mediaType = type;
      _videoCtrl = newCtrl;
    });
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _MediaOption(
              icon: Icons.photo_library_outlined,
              label: 'Photo from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, 'image');
              },
            ),
            if (!kIsWeb)
              _MediaOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera, 'image');
                },
              ),
            _MediaOption(
              icon: Icons.videocam_outlined,
              label: 'Video from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, 'video');
              },
            ),
            if (!kIsWeb)
              _MediaOption(
                icon: Icons.video_call_outlined,
                label: 'Record a Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera, 'video');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _removeMedia() {
    _videoCtrl?.dispose();
    setState(() {
      _mediaFile = null;
      _mediaBytes = null;
      _mediaType = null;
      _videoCtrl = null;
    });
  }

  bool get _hasMedia => _mediaFile != null || _mediaBytes != null;

  // ─────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the title and body.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      String? mediaUrl;

      if (_hasMedia && _mediaType != null) {
        if (kIsWeb && _mediaBytes != null) {
          mediaUrl =
              await widget.service.uploadMediaBytes(_mediaBytes!, _mediaType!);
        } else if (_mediaFile != null) {
          mediaUrl = await widget.service.uploadMedia(_mediaFile!, _mediaType!);
        }
      }

      final displayName =
          widget.user.displayName ?? widget.user.email ?? 'Anonymous';

      await widget.service.createPost(PostModel(
        id: '',
        authorId: widget.user.uid,
        author: displayName,
        initials: PostModel.initialsFrom(displayName),
        avatarUrl: widget.user.photoURL,
        createdAt: DateTime.now(),
        tag: _selectedTopic,
        tagIcon: _tagIcons[_selectedTopic] ?? 'chat',
        title: title,
        body: body,
        isAnonymous: _isAnonymous,
        mediaUrl: mediaUrl,
        mediaType: _mediaType,
      ));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'New Discussion',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 18),

            // Topic chips
            _sectionLabel('TOPIC'),
            const SizedBox(height: 8),
            _buildTopicChips(),
            const SizedBox(height: 16),

            // Title
            _sectionLabel('TITLE'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration("What's on your mind?"),
            ),
            const SizedBox(height: 14),

            // Body
            _sectionLabel('BODY'),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyCtrl,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration(
                  'Share your thoughts, ask a question, start a discussion…'),
            ),
            const SizedBox(height: 14),

            // Media preview
            if (_hasMedia) ...[
              _sectionLabel('MEDIA'),
              const SizedBox(height: 8),
              _buildMediaPreview(),
              const SizedBox(height: 12),
            ],

            // Add media button
            if (!_hasMedia) ...[
              GestureDetector(
                onTap: _showMediaPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Add Photo or Video',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Anonymous toggle
            Row(
              children: [
                Switch(
                  value: _isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = v),
                  activeThumbColor: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Post anonymously',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          if (_hasMedia) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Uploading media…',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        'Post Discussion',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  Widget _buildTopicChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _topics.map((t) {
        final active = _selectedTopic == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTopic = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryDark : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: active ? AppColors.primaryDark : AppColors.border),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMediaPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildMediaContent(),
        ),

        // Play/pause overlay for mobile video
        if (_mediaType == 'video' &&
            !kIsWeb &&
            _videoCtrl != null &&
            _videoCtrl!.value.isInitialized)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() {
                _videoCtrl!.value.isPlaying
                    ? _videoCtrl!.pause()
                    : _videoCtrl!.play();
              }),
              child: Center(
                child: Icon(
                  _videoCtrl!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 52,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),

        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: _removeMedia,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),

        // Change button
        Positioned(
          bottom: 6,
          right: 6,
          child: GestureDetector(
            onTap: _showMediaPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Change',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaContent() {
    if (_mediaType == 'image') {
      if (kIsWeb && _mediaBytes != null) {
        return Image.memory(
          _mediaBytes!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      }
      if (_mediaFile != null) {
        return Image.file(
          _mediaFile!,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      }
    }

    if (_mediaType == 'video') {
      if (kIsWeb) {
        return Container(
          height: 140,
          color: Colors.black87,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 36),
                SizedBox(height: 8),
                Text(
                  'Video selected — will upload on post',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
      if (_videoCtrl != null && _videoCtrl!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        );
      }
    }

    return Container(
      height: 120,
      color: Colors.black12,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─────────────────────────────────────────────
// Helper widget for media source options
// ─────────────────────────────────────────────

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
