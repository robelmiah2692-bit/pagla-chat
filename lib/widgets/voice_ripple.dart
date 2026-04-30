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
      duration: const Duration(milliseconds: 1500), // কিছুটা দ্রুত করলে রিয়েল-টাইম ফিল পাওয়া যায়
    );

    if (widget.isTalking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    // যদি কথা বলা শুরু করে তবেই এনিমেশন চলবে, নাহলে পুরোপুরি স্টপ
    if (widget.isTalking != oldWidget.isTalking) {
      if (widget.isTalking) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // মেমোরি লিক রোধ করতে অবশ্যই ডিসপোজ করতে হবে
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // কথা না বললে সরাসরি চাইল্ড রিটার্ন করবে, কোনো এনিমেশন বিল্ডার রান হবে না (Performance Boost)
    if (!widget.isTalking) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRipple(0.0),
            _buildRipple(0.5), // মাত্র ২টি ঢেউ দিচ্ছি ল্যাগ কমানোর জন্য
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildRipple(double delay) {
    double progress = (_controller.value + delay) % 1.0;

    return Transform.scale(
      scale: 1.0 + (progress * 0.7), 
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          width: 60, // আপনার সিটের সাইজ ৫২ হলে ৬০-৬৫ রাখা পারফেক্ট
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.5), // সায়ান কালার সিটের বর্ডারের সাথে ভালো মিলবে
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}