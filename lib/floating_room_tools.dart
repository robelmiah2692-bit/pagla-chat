import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'top_room_leaderboard.dart';
import 'dart:ui'; // Glass effect এর জন্য লাগবে

class FloatingRoomTools extends StatefulWidget {
  final Function(int minutes, String theme) onGiftCountStart;
  final List<dynamic> seats;

  const FloatingRoomTools({
    super.key,
    required this.onGiftCountStart,
    required this.seats,
  });

  @override
  State<FloatingRoomTools> createState() => _FloatingRoomToolsState();
}

class _FloatingRoomToolsState extends State<FloatingRoomTools> with SingleTickerProviderStateMixin {
  Offset position = const Offset(10, 200);
  late AnimationController _gradientController;
  final TextEditingController _themeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // কালার ঘোরার জন্য এনিমেশন কন্ট্রোলার
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  void _showTimeSelector(BuildContext context) {
    int tempTime = 10;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("START GIFT COUNT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                // থিম ইনপুট (ইউজার নিজের ইচ্ছা মতো লিখবে)
                TextField(
                  controller: _themeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter activity theme (e.g. PK Battle)",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  children: [10, 20, 30, 40, 50, 60].map((time) {
                    return ChoiceChip(
                      label: Text("$time Min"),
                      selected: tempTime == time,
                      onSelected: (val) => setModalState(() => tempTime = time),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  onPressed: () {
                    widget.onGiftCountStart(tempTime, _themeController.text);
                    Navigator.pop(context);
                  },
                  child: const Text("Save & Start"),
                )
              ],
            ),
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
            double x = details.offset.dx;
            double y = details.offset.dy;
            position = Offset(x < 0 ? 0 : x, y < 0 ? 0 : y);
          });
        },
        child: _buildToolPanel(),
      ),
    );
  }

  Widget _buildToolPanel({bool isFeedback = false}) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // গ্লাস ইফেক্ট
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                // রেন্ডম কালার মুভিং ইফেক্ট
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.blueAccent.withOpacity(0.1 + (_gradientController.value * 0.2)),
                    Colors.purpleAccent.withOpacity(0.1 + ((1 - _gradientController.value) * 0.2)),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolIcon(Icons.timer_outlined, "Gift Count", Colors.orangeAccent, () => _showTimeSelector(context)),
          const SizedBox(height: 15),
          _toolIcon(Icons.emoji_events_outlined, "Top Room", Colors.yellowAccent, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TopRoomLeaderboard()));
          }),
          const SizedBox(height: 15),
          _toolIcon(Icons.bolt, "Personal PK", Colors.blueAccent, () {}),
          const SizedBox(height: 15),
          _toolIcon(Icons.whatshot, "VS PK", Colors.redAccent, () {}),
        ],
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
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}



// ---------------------------------------------------------
// গিফট কাউন্টার ভাসমান ব্যানার (Glass Ranking View)
// ---------------------------------------------------------

class GiftCalculatorBanner extends StatefulWidget {
  final int minutes;
  final String theme;
  final List<dynamic> seats;
  final String roomId; // রুম আইডি পাস করা জরুরি
  final VoidCallback onClose;

  const GiftCalculatorBanner({
    super.key,
    required this.minutes,
    required this.theme,
    required this.seats,
    required this.roomId,
    required this.onClose,
  });

  @override
  State<GiftCalculatorBanner> createState() => _GiftCalculatorBannerState();
}

class _GiftCalculatorBannerState extends State<GiftCalculatorBanner> {
  late Timer _timer;
  int _secondsRemaining = 0;
  Map<String, int> scores = {};
  StreamSubscription? _giftSubscription;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.minutes * 60;
    _startTimer();
    _listenToGiftUpdates();
  }

  void _listenToGiftUpdates() {
    _giftSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      var data = snapshot.data();
      if (data != null && data.containsKey('last_gift')) {
        var giftData = data['last_gift'];
        
        // এখানে আপনার ডাটাবেস স্ট্রাকচার অনুযায়ী uID এবং count নেয়া হচ্ছে
        String userId = giftData['uID']?.toString() ?? "";
        int currentCount = int.tryParse(giftData['count']?.toString() ?? "0") ?? 0;

        if (userId.isNotEmpty) {
          setState(() {
            scores[userId] = currentCount;
          });
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _giftSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ১. ফিল্টার করা: যারা সিটে আছে এবং গিফট পেয়েছে
    final activeParticipants = widget.seats
        .where((s) => s != null && s['uID'] != null && (s['isOccupied'] == true))
        .toList();

    // ২. সর্ট করা: বেশি গিফট পাওয়া ইউজার উপরে থাকবে
    activeParticipants.sort((a, b) {
      int scoreA = scores[a['uID'].toString()] ?? 0;
      int scoreB = scores[b['uID'].toString()] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    String timeStr = "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}";

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // হেডার
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.theme.isEmpty ? "GIFT COUNT" : widget.theme,
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
                // র‍্যাঙ্কিং লিস্ট
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeParticipants.length,
                    itemBuilder: (context, index) {
                      final seat = activeParticipants[index];
                      String uID = seat['uID'].toString();
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundImage: seat['userImage'] != null && seat['userImage'].isNotEmpty
                              ? NetworkImage(seat['userImage'])
                              : null,
                        ),
                        title: Text(seat['userName'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 10)),
                        trailing: Text(
                          "${scores[uID] ?? 0} 💎",
                          style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}