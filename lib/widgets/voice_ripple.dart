import 'package:flutter/material.dart';

class VoiceRipple extends StatefulWidget {
  final Widget child;
  final bool isTalking; // কথা বললে এটি true হবে

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
            // পানির ঢেউয়ের মতো ৩টি লেয়ার
            if (widget.isTalking) ...[
              _buildRipple(1.0 + (_controller.value * 0.5), 1.0 - _controller.value),
              _buildRipple(1.0 + ((_controller.value + 0.3) % 1.0 * 0.5), 1.0 - ((_controller.value + 0.3) % 1.0)),
            ],
            widget.child, // ইউজারের প্রোফাইল পিকচার
          ],
        );
      },
    );
  }

  Widget _buildRipple(double scale, double opacity) {
    return Container(
      width: 80, // সিটের সাইজ অনুযায়ী কম-বেশি করতে পারবেন
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.pinkAccent.withOpacity(opacity * 0.5),
      ),
      transform: Matrix4.identity()..scale(scale),
    );
  }
}
