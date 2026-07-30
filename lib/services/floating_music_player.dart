import 'package:flutter/material.dart';

class FloatingMusicPlayer extends StatefulWidget {
  final Offset initialPosition;
  final Function(Offset) onDragEnd;
  final bool isRoomMusicPlaying;
  final Future<void> Function() onPlayPauseToggle;
  final VoidCallback onClose;

  const FloatingMusicPlayer({
    Key? key,
    required this.initialPosition,
    required this.onDragEnd,
    required this.isRoomMusicPlaying,
    required this.onPlayPauseToggle,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FloatingMusicPlayer> createState() => _FloatingMusicPlayerState();
}

class _FloatingMusicPlayerState extends State<FloatingMusicPlayer> {
  late Offset position;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
  }

  // ✅ প্রপার্টি আপডেট হলে পজিশন সিংকে রাখার জন্য
  @override
  void didUpdateWidget(covariant FloatingMusicPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPosition != widget.initialPosition) {
      position = widget.initialPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: RepaintBoundary( // ✅ গ্রাফিক্স রেন্ডারিং আইসোলেট করার জন্য
        child: Draggable(
          feedback: _buildPlayerContent(isDragging: true),
          childWhenDragging: Container(),
          onDragEnd: (details) {
            setState(() {
              position = details.offset;
            });
            widget.onDragEnd(details.offset);
          },
          child: _buildPlayerContent(isDragging: false),
        ),
      ),
    );
  }

  Widget _buildPlayerContent({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.music_note_rounded,
              color: Colors.pinkAccent,
              size: 16,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onPlayPauseToggle,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0080), Color(0xFF00B2FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRoomMusicPlaying
                              ? Colors.pinkAccent
                              : Colors.blueAccent)
                          .withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isRoomMusicPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClose,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}