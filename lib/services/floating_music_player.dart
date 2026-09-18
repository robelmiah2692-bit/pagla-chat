import 'package:flutter/material.dart';

class FloatingMusicPlayer extends StatefulWidget {
  final Offset initialPosition;
  final Function(Offset) onDragEnd;
  final bool isRoomMusicPlaying;
  final Future<void> Function() onPlayPauseToggle;
  final VoidCallback onClose;
  final VoidCallback? onNext; // ✅ নেক্সট গান পরিবর্তনের জন্য কলব্যাক
  final VoidCallback? onPrevious; // ✅ আগের গান যাওয়ার জন্য কলব্যাক
  final String trackName; // ✅ ট্র্যাক বা গান এর নাম
  final int currentPositionMs; 
  final int totalDurationMs; 
  final Function(double)? onSeek; 

  const FloatingMusicPlayer({
    Key? key,
    required this.initialPosition,
    required this.onDragEnd,
    required this.isRoomMusicPlaying,
    required this.onPlayPauseToggle,
    required this.onClose,
    this.onNext,
    this.onPrevious,
    this.trackName = "Artist - Track Name",
    this.currentPositionMs = 0,
    this.totalDurationMs = 0,
    this.onSeek,
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
      child: RepaintBoundary(
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
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF2196F3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.trackName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ প্রিভিয়াস বাটন সাইজ বড় করা হলো
                GestureDetector(
                  onTap: widget.onPrevious,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.fast_rewind_rounded, color: Colors.white70, size: 24),
                  ),
                ),
                const SizedBox(width: 2),
                // ✅ প্লে/পজ বাটন বড় করা হলো
                GestureDetector(
                  onTap: widget.onPlayPauseToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: Icon(
                      widget.isRoomMusicPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // ✅ নেক্সট বাটন সাইজ বড় করা হলো
                GestureDetector(
                  onTap: widget.onNext,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.fast_forward_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            // ✅ ক্রস বাটনটি নেক্সট বাটন থেকে দূরত্ব বজায় রাখার জন্য গ্যাপ বাড়ানো হলো
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black26,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}