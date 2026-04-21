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
      duration: const Duration(milliseconds: 2000), // ২ সেকেন্ড দিলে আরও স্মুথ হয়
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
            // যখন কথা বলবে তখন ৩টি ঢেউ তৈরি হবে
            if (widget.isTalking) ...[
              _buildRipple(0.0),
              _buildRipple(0.33),
              _buildRipple(0.66),
            ],
            // ইউজারের ছবি বা সিট উইজেট
            widget.child,
          ],
        );
      },
    );
  }

  Widget _buildRipple(double delay) {
    // এনিমেশনের ভ্যালুর সাথে ডিলে যোগ করে ০.০ থেকে ১.০ এর মধ্যে রাখা
    double progress = (_controller.value + delay) % 1.0;

    return Transform.scale(
      // ঢেউটি ১.০ (আসল সাইজ) থেকে ২.০ গুণ পর্যন্ত বড় হবে
      scale: 1.0 + (progress * 0.8), 
      child: Opacity(
        // ঢেউ যত বড় হবে তত স্বচ্ছ (transparent) হয়ে যাবে
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          width: 75, // আপনার সিটের সাইজ অনুযায়ী এটা কম-বেশি করতে পারেন
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.pinkAccent.withOpacity(0.4),
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}