import 'package:flutter/material.dart';

class FloatingBubbleService {
  static OverlayEntry? _overlayEntry;
  static bool isMinimized = false;
  static Offset _offset = const Offset(20, 120); // শুরুর পজিশন

  static void show(BuildContext context, String roomId, String imageUrl, Widget destinationPage) {
    if (_overlayEntry != null) return;
    isMinimized = true; // বাবল দেখানোর সময় এটিকে true করে দিন
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _FloatingBubble(
          imageUrl: imageUrl,
          destinationPage: destinationPage,
          initialOffset: _offset,
          onPositionChanged: (newOffset) {
            _offset = newOffset; // পজিশন আপডেট করে রাখা
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // এখানে শুধু ওভারলে রিমোভ করবে, isMinimized সাথে সাথে false করবে না
  static void clearOverlayOnly() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void hide() {
    isMinimized = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// বাবল এবং অ্যানিমেশনের জন্য আলাদা উইজেট
class _FloatingBubble extends StatefulWidget {
  final String imageUrl;
  final Widget destinationPage;
  final Offset initialOffset;
  final Function(Offset) onPositionChanged;

  const _FloatingBubble({
    required this.imageUrl,
    required this.destinationPage,
    required this.initialOffset,
    required this.onPositionChanged,
  });

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble> with SingleTickerProviderStateMixin {
  late Offset offset;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    offset = widget.initialOffset;
    
    // রিপেল অ্যানিমেশন কন্ট্রোলার
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // বারবার চলতে থাকবে
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: offset.dx,
      bottom: offset.dy,
      child: GestureDetector(
        // ড্র্যাগ বা সরানোর লজিক
        onPanUpdate: (details) {
          setState(() {
            offset = Offset(
              offset.dx - details.delta.dx,
              offset.dy - details.delta.dy,
            );
          });
          widget.onPositionChanged(offset);
        },
        onTap: () {
          // শুধু ওভারলে উইজেট সরাব, স্টেট ঠিক রাখার জন্য
          FloatingBubbleService.clearOverlayOnly();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => widget.destinationPage),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // লাইভ রিপেল অ্যানিমেশন (বাতাসের ঢেউয়ের মতো)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Container(
                    width: 75 * _rippleController.value + 65,
                    height: 75 * _rippleController.value + 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pinkAccent.withOpacity(1 - _rippleController.value),
                    ),
                  );
                },
              ),
              // মেইন বাবল
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 1)
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(widget.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black26,
                  ),
                  child: const Icon(Icons.multitrack_audio, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}