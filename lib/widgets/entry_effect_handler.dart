import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class EntryEffectHandler extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String effectUrl;
  final VoidCallback onFinished;

  const EntryEffectHandler({
    super.key,
    required this.userName,
    this.userImage,
    required this.effectUrl,
    required this.onFinished,
  });

  @override
  State<EntryEffectHandler> createState() => _EntryEffectHandlerState();
}

class _EntryEffectHandlerState extends State<EntryEffectHandler> {
  @override
  void initState() {
    super.initState();
    // ৫ সেকেন্ড পর ইফেক্টটি বন্ধ হয়ে যাবে
    Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ১. এনিমেশন লোড করা
            Lottie.network(
              widget.effectUrl,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),

            // ২. ইউজারের তথ্য মাঝখানে দেখানো
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.userImage != null && widget.userImage!.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(widget.userImage!),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  "${widget.userName} Entered",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}