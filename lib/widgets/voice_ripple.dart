import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceRipple extends StatefulWidget {
  final Widget child;
  final bool isTalking;
  final int seatIndex;
  // নতুন প্যারামিটারগুলো এখানে যোগ করলাম
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

  final List<Color> rippleColors = [
    Colors.pinkAccent,
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
      duration: const Duration(milliseconds: 2000),
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
          if (widget.isTalking) ...[
            _buildGlossyRipple(0.0, currentColor),
            _buildGlossyRipple(0.5, currentColor),

            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(6, (index) {
                      final angle = (index * 60) * (math.pi / 180);
                      return Transform.translate(
                        offset: Offset(math.cos(angle) * 38, math.sin(angle) * 38),
                        child: Icon(
                          index % 2 == 0 ? Icons.favorite : Icons.auto_awesome,
                          color: currentColor.withOpacity(0.9),
                          size: 10,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ],

          // ৩. মূল অবতার এবং মাইক আইকন (এনিমেটেড)
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
                      double scale = widget.isTalking ? (1.0 + (_controller.value * 0.2)) : 1.0;
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

  Widget _buildGlossyRipple(double delay, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double progress = (_controller.value + delay) % 1.0;
        return Transform.scale(
          scale: 1.0 + (progress * 0.6),
          child: Opacity(
            opacity: (1.0 - progress).clamp(0.0, 1.0),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.0),
                    color.withOpacity(0.3),
                    color.withOpacity(0.0),
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
                border: Border.all(color: color.withOpacity(0.4), width: 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}