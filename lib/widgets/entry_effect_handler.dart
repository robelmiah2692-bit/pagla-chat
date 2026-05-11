import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class EntryEffectHandler extends StatefulWidget {
  final String userName;
  final String? userImage;
  final String? activeFrameUrl; // 🔥 ফ্রেমের জন্য নতুন প্যারামিটার
  final String effectUrl;
  final VoidCallback onFinished;

  const EntryEffectHandler({
    super.key,
    required this.userName,
    this.userImage,
    this.activeFrameUrl, // ফ্রেম ইউআরএল (Lottie বা Image)
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
            // ১. মূল এন্ট্রি এনিমেশন (Lottie)
            Lottie.network(
              widget.effectUrl,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),

            // ২. রয়াল ব্যানার ডিজাইন
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                width: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.9),
                      Colors.purple.withOpacity(0.8),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white30, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // 🔥 প্রোফাইল ছবি এবং ফ্রেমের স্ট্যাক
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // প্রোফাইল ছবি
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: widget.userImage != null && widget.userImage!.isNotEmpty
                                ? NetworkImage(widget.userImage!)
                                : null,
                            child: widget.userImage == null || widget.userImage!.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),

                        // 🔥 ফ্রেম লজিক (Lottie বা Image সাপোর্ট)
                        if (widget.activeFrameUrl != null && widget.activeFrameUrl!.isNotEmpty)
                          Positioned.fill(
                            child: Transform.scale(
                              scale: 2.3, // ফ্রেমের সাইজ বড় করার জন্য
                              child: widget.activeFrameUrl!.contains('.json')
                                  ? Lottie.network(
                                      widget.activeFrameUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    )
                                  : Image.network(
                                      widget.activeFrameUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(width: 15),
                    
                    // নাম এবং "is coming" টেক্সট
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                            ),
                          ),
                          const Text(
                            "is coming",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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