import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_event_manager_widget.dart'; // ইভেন্ট ম্যানেজারের ফাইল

class ViewerRankingWidget extends StatefulWidget {
  final Widget viewerListWidget; 
  final String roomId;
  final Map<String, dynamic> roomData;

  const ViewerRankingWidget({
    Key? key,
    required this.viewerListWidget,
    required this.roomId,
    required this.roomData,
  }) : super(key: key);

  @override
  State<ViewerRankingWidget> createState() => _ViewerRankingWidgetState();
}

class _ViewerRankingWidgetState extends State<ViewerRankingWidget> with SingleTickerProviderStateMixin {
  int _toffeeCount = 1050; 
  Timer? _timer;
  late AnimationController _shiningController;
  late Animation<double> _shiningAnimation;

  @override
  void initState() {
    super.initState();
    _startCounterSimulation();
    
    // সাইনিং ও গ্লোয়িং অ্যানিমেশনের জন্য কন্ট্রোলার
    _shiningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shiningAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _shiningController, curve: Curves.easeInOut),
    );
  }

  void _startCounterSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _toffeeCount += 2; 
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shiningController.dispose();
    super.dispose();
  }

  // সংখ্যা ফরম্যাট করার ফাংশন (যেমন: 1050 -> 1.1k)
  String _formatNumber(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  void _openEventPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: EventDashboardTab(
            roomId: widget.roomId,
            roomData: widget.roomData,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, 
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('room_events')
            .where('status', isEqualTo: 'Live')
            .snapshots(),
        builder: (context, snapshot) {
          bool isEventLive = false;
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            isEventLive = true;
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ১. বাম পাশে টফি বা ট্রফি আইকন এবং তার ঠিক নিচে ছোট টেক্সট
              GestureDetector(
                onTap: _openEventPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // ক্লিন ব্যাকগ্রাউন্ড
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ওপরে রিয়েল গোল্ড গ্রেডিয়েন্ট ট্রফি আইকন
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Icon(
                          isEventLive ? Icons.fiber_manual_record : Icons.emoji_events,
                          color: isEventLive ? const Color(0xFF42F50B) : Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // ঠিক ট্রফির নিচে ছোট সাইজে 1k, 2k ফরম্যাটের রিয়াল গোল্ড কাউন্ট
                      isEventLive
                          ? FadeTransition(
                              opacity: _shiningAnimation,
                              child: const Text(
                                "Live",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          : ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                _formatNumber(_toffeeCount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              
              // ২. ডান পাশে ভিউয়ার লিস্ট এলাকা
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.viewerListWidget,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}