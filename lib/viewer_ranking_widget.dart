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
      height: 55, 
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.6), 
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
      child: StreamBuilder<QuerySnapshot>(
        // রুমের ইভেন্টগুলো রিয়েল-টাইমে মনিটর করার জন্য
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
            children: [
              // টফি বা ইভেন্ট লাইভ বাটন (একই ডিজাইনের ভেতর কন্ডিশন)
              GestureDetector(
                onTap: _openEventPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isEventLive
                        ? const LinearGradient(
                            // আকর্ষণীয় প্রিমিয়াম মিক্স কালার থিম (লাইভ থাকার জন্য)
                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B), Color(0xFFFFA07A), Color(0xFFFFD700)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            // গোল্ডেন থিম (সাধারণ অবস্থায় টফি)
                            colors: [Color(0xFFBF953F), Color(0xFFFCF6BA), Color(0xFFB38728), Color(0xFFFBF5B7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isEventLive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF416C).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEventLive ? Icons.fiber_manual_record : Icons.local_fire_department,
                        color: isEventLive ? const Color.fromARGB(255, 66, 245, 11) : const Color(0xFF5A3E1B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      isEventLive
                          ? FadeTransition(
                              opacity: _shiningAnimation,
                              child: const Text(
                                "Event Live",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 92, 248, 2),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  shadows: [
                                    Shadow(
                                      color: Colors.amberAccent,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : TweenAnimationBuilder<int>(
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
              ),
              const SizedBox(width: 8),
              
              // ভিউয়ার লিস্ট এলাকা
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.viewerListWidget,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}