import 'package:flutter/material.dart';

class VoiceRipple extends StatefulWidget {
  final Widget child;
  final bool isTalking;
  final int seatIndex;
  final bool isMicOn;
  final bool isOccupied;

  const VoiceRipple({
    super.key,
    required this.child,
    required this.isTalking,
    this.seatIndex = 0,
    required this.isMicOn,
    required this.isOccupied,
  });

  @override
  State<VoiceRipple> createState() => _VoiceRippleState();
}

class _VoiceRippleState extends State<VoiceRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 🟢 নতুন ৪টি মিক্স কালার
  final List<Color> rippleColors = [
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    Color currentColor = rippleColors[widget.seatIndex % rippleColors.length];

    return SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 🌊 পানির মতো হালকা ও সফট রিপেল ইফেক্ট (সব সিটের জন্য পারফেক্ট সাইজ)
          if (widget.isTalking) ...[
            _buildWaterRipple(0.0, currentColor),
            _buildWaterRipple(0.5, currentColor),
          ],

          // মূল অবতার এবং মাইক আইকন
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Center(child: widget.child),
              if (widget.isOccupied)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double scale = widget.isTalking ? (1.0 + (_controller.value * 0.15)) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isTalking ? currentColor : Colors.white24,
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            widget.isMicOn ? Icons.mic : Icons.mic_off,
                            color: widget.isMicOn ? (widget.isTalking ? currentColor : Colors.greenAccent) : Colors.redAccent,
                            size: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 💧 পানির মতো হালকা ও সফট রিপেল বিল্ডার (সিটের মাপে সামঞ্জস্যপূর্ণ)
  Widget _buildWaterRipple(double delay, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double progress = (_controller.value + delay) % 1.0;
        return Transform.scale(
          scale: 1.0 + (progress * 0.65), // সিটের ভেতর থেকে শুরু হয়ে চারদিকে ছড়িয়ে যাবে
          child: Opacity(
            opacity: (1.0 - progress).clamp(0.0, 1.0), // আস্তে আস্তে পানির সাথে মিশে অদৃশ্য হবে
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 1.0),
                color: color.withOpacity(0.08),
              ),
            ),
          ),
        );
      },
    );
  }
}