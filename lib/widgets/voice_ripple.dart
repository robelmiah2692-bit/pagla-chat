import 'package:flutter/material.dart';

class VoiceRipple extends StatefulWidget {
  final Widget child;
  final bool isTalking;

  const VoiceRipple({super.key, required this.child, required this.isTalking});

  @override
  State<VoiceRipple> createState() => _VoiceRippleState();
}

class _VoiceRippleState extends State<VoiceRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // একটু বেশি সময় দিলে ঢেউগুলো আরও ন্যাচারাল লাগে
    );

    if (widget.isTalking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking != oldWidget.isTalking) {
      if (widget.isTalking) {
        // শুরুতে এনিমেশন রিসেট করে চালানো ভালো
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isTalking) ...[
              _buildRipple(0.0),
              _buildRipple(0.3),
              _buildRipple(0.6),
            ],
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildRipple(double delay) {
    // প্রোগ্রেস ক্যালকুলেশন আরও নিখুঁত করা হয়েছে
    double progress = (_controller.value + delay) >= 1.0 
        ? (_controller.value + delay) - 1.0 
        : (_controller.value + delay);

    double opacity = (1.0 - progress).clamp(0.0, 1.0);
    double scale = 1.0 + (progress * 0.5);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 70, // সিটের গোল ফ্রেমের সাইজ অনুযায়ী
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.pinkAccent.withOpacity(0.5),
              width: 1.5,
            ),
            // গ্রেডিয়েন্ট দিলে ঢেউটা প্রিমিয়াম দেখাবে
            gradient: RadialGradient(
              colors: [
                Colors.pinkAccent.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
