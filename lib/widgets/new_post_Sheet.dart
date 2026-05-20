import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    super.dispose();
  }

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
      final displayName =
          widget.user.displayName ?? widget.user.email ?? 'Anonymous';
      final parts = displayName.trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : 'U';

      await widget.service.createPost(PostModel(
        id: '', // Firestore assigns the real ID
        authorId: widget.user.uid,
        author: displayName,
        initials: initials,
        avatarUrl: widget.user.photoURL,
        createdAt: DateTime.now(), // only used locally; server timestamp stored
        tag: _selectedTopic,
        tagIcon: _tagIcons[_selectedTopic] ?? 'chat',
        title: title,
        body: body,
        isAnonymous: _isAnonymous,
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

            // ── Topic chips ──
            _sectionLabel('TOPIC'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topics.map((t) {
                final active = _selectedTopic == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTopic = t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color:
                          active ? AppColors.primaryDark : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            active ? AppColors.primaryDark : AppColors.border,
                      ),
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
            ),
            const SizedBox(height: 16),

            // ── Title ──
            _sectionLabel('TITLE'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration("What's on your mind?"),
            ),
            const SizedBox(height: 14),

            // ── Body ──
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
            const SizedBox(height: 12),

            // ── Post anonymously toggle ──
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

            // ── Submit ──
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
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
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
