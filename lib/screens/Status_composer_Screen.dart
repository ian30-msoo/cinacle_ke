import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/status_service.dart';

class StatusComposerScreen extends StatefulWidget {
  const StatusComposerScreen({super.key});

  @override
  State<StatusComposerScreen> createState() => _StatusComposerScreenState();
}

class _StatusComposerScreenState extends State<StatusComposerScreen> {
  static const _backgroundColors = [
    '#1F6F54', // primary-ish green
    '#0E4D38', // primaryDark-ish
    '#B0883A', // gold-ish
    '#2D3142', // slate
    '#7A2E2E', // deep red
    '#264E70', // navy
  ];

  final _textCtrl = TextEditingController();
  int _selectedColorIndex = 0;
  bool _isPosting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  Future<void> _postText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isPosting) return;
    setState(() => _isPosting = true);
    try {
      await StatusService().postTextStatus(
        text,
        backgroundColor: _backgroundColors[_selectedColorIndex],
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        _showError('Couldn\'t post status. Please try again.');
      }
    }
  }

  Future<void> _pickAndPostImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    if (!mounted) return;

    final caption = await _promptCaption(File(picked.path));
    if (caption == null) return; // user cancelled

    setState(() => _isPosting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref(
          'status_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await StatusService().postImageStatus(url, caption: caption);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        _showError('Couldn\'t upload image. Please try again.');
      }
    }
  }

  Future<String?> _promptCaption(File imageFile) {
    final captionCtrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: captionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a caption (optional)',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(sheetContext, captionCtrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Post Status',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(_backgroundColors[_selectedColorIndex]);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Text Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.white),
            tooltip: 'Post an image instead',
            onPressed: _isPosting ? null : _pickAndPostImage,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TextField(
                controller: _textCtrl,
                maxLines: 6,
                minLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Type a status...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                autofocus: true,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 110,
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _backgroundColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final selected = i == _selectedColorIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _hexToColor(_backgroundColors[i]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: selected ? 3 : 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _postText,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bgColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: bgColor),
                    )
                  : const Text('Post Status',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
