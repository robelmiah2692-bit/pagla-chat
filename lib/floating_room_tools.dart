import 'dart:async';
import 'package:flutter/material.dart';
import 'top_room_leaderboard.dart';

class FloatingRoomTools extends StatefulWidget {
  // // ফাংশনে এখন int parameter পাস হবে টাইমিং এর জন্য
  final Function(int minutes) onGiftCountStart;
  final List<dynamic> seats; 

  const FloatingRoomTools({
    super.key, 
    required this.onGiftCountStart, 
    required this.seats
  });

  @override
  State<FloatingRoomTools> createState() => _FloatingRoomToolsState();
}

class _FloatingRoomToolsState extends State<FloatingRoomTools> {
  Offset position = const Offset(10, 200);

  // // ১০-৬০ মিনিটের টাইম সিলেক্টর পপ-আপ
  void _showTimeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("SELECT DURATION", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 25),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: [10, 20, 30, 40, 50, 60].map((time) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onGiftCountStart(time);
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.3), Colors.blue.withOpacity(0.1)]),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text("$time Min", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

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
            // // স্ক্রিনের বাইরে যেন চলে না যায় তার চেক
            double x = details.offset.dx;
            double y = details.offset.dy;
            if (x < 0) x = 0;
            if (y < 0) y = 0;
            position = Offset(x, y);
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolIcon(Icons.timer_outlined, "Gift Count", Colors.orangeAccent, () => _showTimeSelector(context)),
            const SizedBox(height: 15),
            _toolIcon(Icons.emoji_events_outlined, "Top Room", Colors.yellowAccent, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TopRoomLeaderboard()));
            }),
            const SizedBox(height: 15),
            _toolIcon(Icons.bolt, "Personal PK", Colors.blueAccent, () {
               // // এখানে আপনার PK ফাইলের Navigation দিবেন
            }),
            const SizedBox(height: 15),
            _toolIcon(Icons.whatshot, "VS PK", Colors.redAccent, () {
               // // এখানে আপনার VS PK ফাইলের Navigation দিবেন
            }),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color.withOpacity(0.4), color.withOpacity(0.1)]),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// // ---------------------------------------------------------
// // গিফট কাউন্টার ভাসমান ব্যানার (ক্যালকুলেটর ভিউ)
// // ---------------------------------------------------------

class GiftCalculatorBanner extends StatefulWidget {
  final int minutes;
  final List<dynamic> seats;
  final VoidCallback onClose;

  const GiftCalculatorBanner({super.key, required this.minutes, required this.seats, required this.onClose});

  @override
  State<GiftCalculatorBanner> createState() => _GiftCalculatorBannerState();
}

class _GiftCalculatorBannerState extends State<GiftCalculatorBanner> {
  late Timer _timer;
  int _secondsRemaining = 0;
  // // ডাটাবেস থেকে রিয়েল টাইম পয়েন্ট আপডেট নেওয়ার জন্য স্ট্রীম বা ম্যাপ ব্যবহার করবেন
  Map<String, int> scores = {}; 

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.minutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        _showWinnerDialog();
      }
    });
  }

  void _showWinnerDialog() {
    // // এখানে আপনার উইনার পপ-আপ লজিক বসবে (সবচেয়ে বেশি ডায়মন্ড পাওয়া ইউজারের জন্য)
    // // এবং স্টোরি শেয়ার বাটন
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timeStr = "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF161B40).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
          boxShadow: [const BoxShadow(color: Colors.black87, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // // হেডার
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("GIFT COUNT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close, color: Colors.white54, size: 16)),
                ],
              ),
            ),
            // // সিট ইউজার লিস্ট
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: widget.seats.length,
                itemBuilder: (context, index) {
                  final seat = widget.seats[index];
                  if (seat == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundImage: NetworkImage(seat['userImage'] ?? "")),
                        const SizedBox(width: 10),
                        Expanded(child: Text(seat['userName'] ?? "User", style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.diamond, color: Colors.blueAccent, size: 12),
                        Text(" ${scores[seat['uid']] ?? 0}", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
