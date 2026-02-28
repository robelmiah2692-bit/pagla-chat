import 'dart:async';
import 'package:flutter/material.dart';
import 'top_room_leaderboard.dart'; // এই লাইনটি অবশ্যই যোগ করবেন

class FloatingRoomTools extends StatefulWidget {
  final Function onGiftCountStart;
  const FloatingRoomTools({super.key, required this.onGiftCountStart});

  @override
  State<FloatingRoomTools> createState() => _FloatingRoomToolsState();
}

class _FloatingRoomToolsState extends State<FloatingRoomTools> {
  Offset position = const Offset(10, 200); 

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: _buildToolPanel(isFeedback: true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            // স্ক্রিনের লিমিট অনুযায়ী পজিশন সেট করা
            position = details.offset;
          });
        },
        child: _buildToolPanel(),
      ),
    );
  }

  Widget _buildToolPanel({bool isFeedback = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolIcon(Icons.timer_outlined, "Gift Count", Colors.orangeAccent, () => widget.onGiftCountStart()),
            const SizedBox(height: 12),
            
            // --- এইখানে আমরা লিডারবোর্ড কানেক্ট করলাম ---
            _toolIcon(Icons.emoji_events_outlined, "Top Room", Colors.yellowAccent, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TopRoomLeaderboard()),
              );
            }),
            
            const SizedBox(height: 12),
            _toolIcon(Icons.bolt, "Personal PK", Colors.blueAccent, () {}),
            const SizedBox(height: 12),
            _toolIcon(Icons.whatshot, "VS PK", Colors.redAccent, () {}),
          ],
        ),
      ),
    );
  }

  Widget _toolIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
        ],
      ),
    );
  }
}
