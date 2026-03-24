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
    );

    // ১. শুরুতে চেক করা কথা বলছে কিনা
    if (widget.isTalking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ২. 🛡️ গুরুত্বপূর্ণ ফিক্স: কথা বলা শুরু করলে এনিমেশন চলবে, থামলে বন্ধ হবে
    if (widget.isTalking != oldWidget.isTalking) {
      if (widget.isTalking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset(); // ঢেউগুলো মুছে ফেলার জন্য
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
            // ৩. কথা বললে ৩টি ঢেউয়ের লেয়ার তৈরি হবে
            if (widget.isTalking) ...[
              _buildRipple(_controller.value, 0),
              _buildRipple(_controller.value, 0.4),
              _buildRipple(_controller.value, 0.8),
            ],
            widget.child, // ইউজারের প্রোফাইল পিকচার
          ],
        );
      },
    );
  }

  // ৪. ঢেউ তৈরির লজিক (স্মুথ করা হয়েছে)
  Widget _buildRipple(double value, double delay) {
    double progress = (value + delay) % 1.0;
    double opacity = (1.0 - progress).clamp(0.0, 1.0);
    double scale = 1.0 + (progress * 0.6); // ঢেউ কতটুকু বড় হবে

    return Container(
      width: 75, // সিটের সাইজ অনুযায়ী ঠিক আছে
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.pinkAccent.withOpacity(opacity * 0.6),
          width: 2,
        ),
        // শুধু বর্ডার দিলে দেখতে বেশি প্রফেশনাল লাগে, চাইলে কালারও দিতে পারেন
        color: Colors.pinkAccent.withOpacity(opacity * 0.15),
      ),
      transform: Matrix4.identity()..scale(scale),
    );
  }
}
