import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class EntryEffectHandler extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String? activeFrameUrl;
  final String effectUrl;
  final VoidCallback onFinished;

  const EntryEffectHandler({
    super.key,
    required this.userName,
    this.userImage,
    this.activeFrameUrl,
    required this.effectUrl,
    required this.onFinished,
  });

  @override
  State<EntryEffectHandler> createState() => _EntryEffectHandlerState();
}

class _EntryEffectHandlerState extends State<EntryEffectHandler> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ৫ সেকেন্ড পর অটোমেটিক বন্ধ হবে যাতে স্ক্রিন ব্লক না থাকে
    Timer(const Duration(seconds: 6), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ইফেক্ট ইউআরএল খালি থাকলে কিছুই দেখাবে না
    if (widget.effectUrl.isEmpty) {
      widget.onFinished();
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer( // টাচ করলে যাতে সমস্যা না হয়
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ১. মূল এন্ট্রি এনিমেশন (Lottie)
            Lottie.network(
              widget.effectUrl,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
              // এনিমেশন লোড হতে দেরি হলে বা এরর হলে যাতে অ্যাপ না ক্রাশ করে
              errorBuilder: (context, error, stackTrace) {
                debugPrint("Lottie Error: $error");
                return const SizedBox.shrink();
              },
            ),

            // ২. রয়াল ব্যানার ডিজাইন
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3, // একটু নিচে নামিয়ে দেওয়া হয়েছে
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                width: MediaQuery.of(context).size.width * 0.8, // রেসপন্সিভ উইডথ
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.9),
                      Colors.purple.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30), // ফুল রাউন্ডেড লুকে বেশি ভালো লাগে
                  border: Border.all(color: Colors.yellowAccent.withOpacity(0.5), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: Row(
                  children: [
                    // প্রোফাইল ছবি এবং ফ্রেম
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: (widget.userImage != null && widget.userImage!.isNotEmpty)
                                ? NetworkImage(widget.userImage!)
                                : null,
                            child: (widget.userImage == null || widget.userImage!.isEmpty)
                                ? const Icon(Icons.person)
                                : null,
                          ),
                        ),

                        // ফ্রেম লজিক
                        if (widget.activeFrameUrl != null && widget.activeFrameUrl!.isNotEmpty)
                          Positioned(
                            // ফ্রেমটি ছবির চারদিকে পারফেক্টলি বসানোর জন্য
                            width: 85, 
                            height: 85,
                            child: widget.activeFrameUrl!.contains('.json')
                                ? Lottie.network(widget.activeFrameUrl!, fit: BoxFit.contain)
                                : Image.network(widget.activeFrameUrl!, fit: BoxFit.contain),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    
                    // নাম এবং টেক্সট
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            "is coming...",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}