import 'package:flutter/material.dart';

class AnimatedProfileFrame extends StatefulWidget {
  final String frameUrl;
  final double size;

  const AnimatedProfileFrame({super.key, required this.frameUrl, this.size = 160});

  @override
  State<AnimatedProfileFrame> createState() => _AnimatedProfileFrameState();
}

class _AnimatedProfileFrameState extends State<AnimatedProfileFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // ২ সেকেন্ড পর পর এনিমেশন হবে
    )..repeat(reverse: true); // একবার বড় হবে, একবার ছোট হবে

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.slowMiddle),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value, // ফ্রেমটি হালকা বড়-ছোট হবে
          child: Opacity(
            opacity: _glowAnimation.value, // লাইট জ্বলবে আর নিভবে
            child: Image.network(
              widget.frameUrl,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
