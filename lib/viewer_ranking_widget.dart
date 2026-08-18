import 'dart:async';
import 'package:flutter/material.dart';

class ViewerRankingWidget extends StatefulWidget {
  final Widget viewerListWidget; // আপনার অরিজিনাল ভিউয়ার লিস্ট উইজেট
  final String roomId;

  const ViewerRankingWidget({
    Key? key,
    required this.viewerListWidget,
    required this.roomId,
  }) : super(key: key);

  @override
  State<ViewerRankingWidget> createState() => _ViewerRankingWidgetState();
}

class _ViewerRankingWidgetState extends State<ViewerRankingWidget> {
  int _toffeeCount = 1050; // ডেমো কাউন্ট, ফায়ারবেস বা লোকাল লজিক অনুযায়ী যুক্ত করতে পারেন
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCounterSimulation();
  }

  void _startCounterSimulation() {
    // প্রতি সেকেন্ডে কাউন্ট বাড়ার অ্যানিমেশন লজিক
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _toffeeCount += 2; // প্রতি সেকেন্ডেIncrement
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55, // ভিউয়ার লিস্টের উচ্চতা লম্বায় কমিয়ে ছোট করা হয়েছে
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.6), // রিয়েল গোল্ড বর্ডার
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // বাম পাশের গোল্ডেন টফি ও রুম র‍্যাঙ্কিং ডিজাইন
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFBF953F), Color(0xFFFCF6BA), Color(0xFFB38728), Color(0xFFFBF5B7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF5A3E1B),
                  size: 16,
                ),
                const SizedBox(width: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _toffeeCount),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Text(
                      "Toffee: $value",
                      style: const TextStyle(
                        color: Color(0xFF3D2300),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // ডান পাশে কম্প্যাক্ট করা ভিউয়ার লিস্ট এলাকা
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.viewerListWidget,
            ),
          ),
        ],
      ),
    );
  }
}