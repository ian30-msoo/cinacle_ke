import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/status_service.dart';

class StatusViewerScreen extends StatefulWidget {
  final UserStatusGroup group;
  final bool isMyStatus;

  const StatusViewerScreen({
    super.key,
    required this.group,
    this.isMyStatus = false,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 6);

  late AnimationController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _startCurrent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  StatusItem get _current => widget.group.items[_index];

  void _startCurrent() {
    _controller.reset();
    _controller.forward();
    StatusService().markViewed(_current.id);
  }

  void _next() {
    if (_index >= widget.group.items.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() => _index++);
    _startCurrent();
  }

  void _prev() {
    if (_index == 0) {
      _startCurrent();
      return;
    }
    setState(() => _index--);
    _startCurrent();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.stop();
  }

  void _onTapUp(TapUpDetails details, double screenWidth) {
    if (details.localPosition.dx < screenWidth / 3) {
      _prev();
    } else {
      _controller.forward();
    }
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final item = _current;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: (d) => _onTapUp(d, screenWidth),
        onTapCancel: _onTapCancel,
        onLongPressStart: (_) => _controller.stop(),
        onLongPressEnd: (_) => _controller.forward(),
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            _prev();
          } else if ((details.primaryVelocity ?? 0) < -200) {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _StatusContent(item: item),

            // Top gradient for readability of header/progress bars
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 140,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressBars(
                    count: widget.group.items.length,
                    currentIndex: _index,
                    controller: _controller,
                  ),
                  const SizedBox(height: 10),
                  _Header(group: widget.group, createdAt: item.createdAt),
                ],
              ),
            ),

            if (widget.isMyStatus)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ViewerFooter(statusId: item.id),
              ),
          ],
        ),
      ),
    );
  }
}

//  Status content (text or image)

class _StatusContent extends StatelessWidget {
  final StatusItem item;
  const _StatusContent({required this.item});

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    if (item.type == StatusType.image && item.imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.imageUrl!,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 48),
            ),
          ),
          if (item.text.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 90,
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ),
        ],
      );
    }

    final bg = item.backgroundColor != null
        ? _hexToColor(item.backgroundColor!)
        : AppColors.primaryDark;

    return Container(
      color: bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        item.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

//  Progress bars

class _ProgressBars extends StatelessWidget {
  final int count;
  final int currentIndex;
  final AnimationController controller;

  const _ProgressBars({
    required this.count,
    required this.currentIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(count, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 2.5,
                  child: i < currentIndex
                      ? const ColoredBox(color: Colors.white)
                      : i > currentIndex
                          ? ColoredBox(color: Colors.white.withOpacity(0.35))
                          : AnimatedBuilder(
                              animation: controller,
                              builder: (_, __) => LinearProgressIndicator(
                                value: controller.value,
                                backgroundColor: Colors.white.withOpacity(0.35),
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

//  Header (avatar, name, time, close)

class _Header extends StatelessWidget {
  final UserStatusGroup group;
  final DateTime createdAt;

  const _Header({required this.group, required this.createdAt});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().add_jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ClipOval(
            child: group.userAvatar != null && group.userAvatar!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: group.userAvatar!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 36,
                    height: 36,
                    color: AppColors.primary,
                    child: Center(
                      child: Text(
                        group.userName.isNotEmpty
                            ? group.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                Text(
                  _formatTime(createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

//  Viewer footer (only shown on your own status — "Viewed by N")

class _ViewerFooter extends StatelessWidget {
  final String statusId;
  const _ViewerFooter({required this.statusId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        onTap: () => _showViewers(context),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<List<MapEntry<String, DateTime>>>(
            future: StatusService().viewersOf(statusId),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    count == 0
                        ? 'No views yet'
                        : '$count view${count > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const Spacer(),
                  if (count > 0)
                    const Icon(Icons.keyboard_arrow_up,
                        color: Colors.white70, size: 18),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showViewers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<List<MapEntry<String, DateTime>>>(
          future: StatusService().viewersOf(statusId),
          builder: (context, snap) {
            final viewers = snap.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${viewers.length} view${viewers.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (viewers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No one has viewed this status yet.',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ...viewers.map((v) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          DateFormat.MMMd().add_jm().format(v.value),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
