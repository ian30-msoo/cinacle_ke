import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/post_model.dart';
import '../services/lets_talk_service.dart';
import 'room_chat_screen.dart';

class PrivateRoomsSheet extends StatefulWidget {
  final LetsTalkService service;
  final User user;

  const PrivateRoomsSheet(
      {super.key, required this.service, required this.user});

  @override
  State<PrivateRoomsSheet> createState() => _PrivateRoomsSheetState();
}

class _PrivateRoomsSheetState extends State<PrivateRoomsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.primaryDark, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Private Rooms',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openCreateDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tab,
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryDark,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'My Rooms'), Tab(text: 'Join a Room')],
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MyRoomsTab(service: widget.service, userId: widget.user.uid),
                _JoinRoomTab(service: widget.service, user: widget.user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _CreateRoomDialog(service: widget.service, user: widget.user),
    );
  }
}

// ─── My Rooms tab ─────────────────────────────────────────────────────────────

class _MyRoomsTab extends StatelessWidget {
  final LetsTalkService service;
  final String userId;

  const _MyRoomsTab({required this.service, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PrivateRoom>>(
      stream: service.streamMyRooms(userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snap.data ?? [];
        if (rooms.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'You haven\'t joined any rooms yet.\nUse "Join a Room" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _RoomCard(
            room: rooms[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomChatScreen(
                  room: rooms[i],
                  userId: userId,
                  service: service,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Join Room tab ────────────────────────────────────────────────────────────

class _JoinRoomTab extends StatefulWidget {
  final LetsTalkService service;
  final User user;

  const _JoinRoomTab({required this.service, required this.user});

  @override
  State<_JoinRoomTab> createState() => _JoinRoomTabState();
}

class _JoinRoomTabState extends State<_JoinRoomTab> {
  final _roomIdCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    _passcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final roomId = _roomIdCtrl.text.trim();
    final passcode = _passcodeCtrl.text.trim();
    if (roomId.isEmpty || passcode.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final success = await widget.service.joinRoom(
        roomId: roomId,
        userId: widget.user.uid,
        passcode: passcode,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You joined the room!')),
        );
        _roomIdCtrl.clear();
        _passcodeCtrl.clear();
      } else {
        setState(() => _error = 'Incorrect passcode or room not found.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask the room creator for their Room ID and passcode, then enter them below.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _label('ROOM ID'),
          const SizedBox(height: 6),
          TextField(
            controller: _roomIdCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDec('Paste the Room ID here'),
          ),
          const SizedBox(height: 14),
          _label('PASSCODE'),
          const SizedBox(height: 6),
          TextField(
            controller: _passcodeCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 6),
            decoration: _inputDec('• • • •').copyWith(counterText: ''),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joining ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _joining
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Join Room',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─── Create Room dialog ───────────────────────────────────────────────────────

class _CreateRoomDialog extends StatefulWidget {
  final LetsTalkService service;
  final User user;

  const _CreateRoomDialog({required this.service, required this.user});

  @override
  State<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<_CreateRoomDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _passcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final passcode = _passcodeCtrl.text.trim();
    if (name.isEmpty || passcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room name and passcode are required.')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      await widget.service.createRoom(
        name: name,
        description: _descCtrl.text.trim(),
        passcode: passcode,
        createdById: widget.user.uid,
        createdByName:
            widget.user.displayName ?? widget.user.email ?? 'Anonymous',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Room created! Share the ID and passcode with members.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 20),
          SizedBox(width: 8),
          Text('Create Private Room',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('ROOM NAME', _nameCtrl, 'e.g. Intercessors Circle'),
            const SizedBox(height: 12),
            _field('DESCRIPTION', _descCtrl, 'What is this room about?'),
            const SizedBox(height: 12),
            _field('PASSCODE', _passcodeCtrl, 'e.g. 1234',
                keyboardType: TextInputType.number, maxLength: 6),
            const SizedBox(height: 6),
            const Text(
              'Share this passcode only with people you want to invite.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _creating ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _creating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.textMuted),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

// ─── Room card (in My Rooms list) ────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final PrivateRoom room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline,
                  color: AppColors.primaryDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  if (room.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(room.description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${room.memberCount} member${room.memberCount == 1 ? '' : 's'}  •  by ${room.createdByName}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
