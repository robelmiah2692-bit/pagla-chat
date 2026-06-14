import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// --- PK Setup View ---
class PKSetupView extends StatefulWidget {
  final List<Map<String, dynamic>> seatedUsers; 
  final Function(Map<String, dynamic> u1, Map<String, dynamic> u2, int duration) onStart;

  const PKSetupView({super.key, required this.seatedUsers, required this.onStart});

  @override
  State<PKSetupView> createState() => _PKSetupViewState();
}

class _PKSetupViewState extends State<PKSetupView> {
  List<Map<String, dynamic>> selectedUsers = [];
  int selectedDuration = 5;

  @override
  Widget build(BuildContext context) {
    // শুধু যাদের সিট অক্যুপাইড আছে তাদের ফিল্টার করছি
    final occupiedSeats = widget.seatedUsers.where((s) => s['isOccupied'] == true).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Select 2 Users for PK", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          SizedBox(
            height: 120,
            child: occupiedSeats.isEmpty 
            ? const Center(child: Text("No users on mic", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: occupiedSeats.length,
              itemBuilder: (context, index) {
                var user = occupiedSeats[index];
                bool isSelected = selectedUsers.contains(user);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUsers.remove(user);
                      } else if (selectedUsers.length < 2) {
                        selectedUsers.add(user);
                      }
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent.withOpacity(0.4) : Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: user['userImage'].isNotEmpty 
                              ? NetworkImage(user['userImage']) 
                              : const NetworkImage('https://cdn-icons-png.flaticon.com/512/847/847969.png'),
                        ),
                        const SizedBox(height: 5),
                        Text(user['userName'], style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [5, 10].map((min) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: ChoiceChip(
                label: Text("$min Min"),
                selected: selectedDuration == min,
                onSelected: (val) => setState(() => selectedDuration = min),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedUsers.length == 2 ? Colors.blueAccent : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)
            ),
            onPressed: selectedUsers.length == 2 
                ? () => widget.onStart(selectedUsers[0], selectedUsers[1], selectedDuration) 
                : null,
            child: const Text("START PK"),
          ),
        ],
      ),
    );
  }
}



class PersonalPKView extends StatefulWidget {
  final Map<String, dynamic> user1;
  final Map<String, dynamic> user2;
  final int duration;
  final int score1;
  final int score2;
  final VoidCallback onTimerEnd;
  // আপনি চাইলে এখানে ব্যাকগ্রাউন্ড ইমেজ লিংকটি কন্ট্রোল করতে পারেন
  final String backgroundImage = "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/vspkbenar.png"; 

  const PersonalPKView({
    super.key,
    required this.user1,
    required this.user2,
    required this.duration,
    required this.score1,
    required this.score2,
    required this.onTimerEnd,
  });

  @override
  State<PersonalPKView> createState() => _PersonalPKViewState();
}

class _PersonalPKViewState extends State<PersonalPKView> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    startTimer();
  }

  @override
  void didUpdateWidget(covariant PersonalPKView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score1 != widget.score1 || oldWidget.score2 != widget.score2) {
      setState(() {});
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          widget.onTimerEnd();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String get timerString {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    bool isEndingSoon = _remainingSeconds <= 10;
    double totalScore = (widget.score1 + widget.score2).toDouble();
    double progress = totalScore == 0 ? 0.5 : widget.score1 / totalScore;

    return FadeTransition(
      opacity: isEndingSoon ? _glowController : const AlwaysStoppedAnimation(1.0),
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isEndingSoon ? Colors.redAccent : Colors.blueAccent, width: 2),
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.backgroundImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
          ),
        ),
        child: Column(
          children: [
            Text(timerString, style: TextStyle(color: isEndingSoon ? Colors.red : Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // আগুনের শিখার ডাইনামিক প্রগ্রেস বার সেকশন
LayoutBuilder(builder: (context, constraints) {
  final double maxWidth = constraints.maxWidth;
  // প্রগ্রেস অনুযায়ী বারের দৈর্ঘ্য
  final double barWidth = maxWidth * progress; 

  return Container(
    height: 12, // বারের উচ্চতা
    width: maxWidth,
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none, // আগুনের বিন্দুটি যেন বাইরে বের হতে পারে
        children: [
          // ১. মূল গোল্ডেন শিমার ইফেক্ট
          if (barWidth > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: barWidth,
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFFFD700), // গোল্ডেন
                highlightColor: const Color(0xFFFF4500), // আগুনের লাল
                period: const Duration(milliseconds: 1500),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFC107), Color(0xFFFFD700)],
                    ),
                  ),
                ),
              ),
            ),
          
          // ২. মাথায় সেই জ্বলজ্বলে আগুনের বিন্দু
          if (barWidth > 0)
            Positioned(
              left: barWidth - 5, // ঠিক প্রগ্রেস বারের মাথায় পজিশন
              top: -4, // বারের একটু উপরে উঠিয়ে রাখা
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFFF4500),
                highlightColor: Colors.yellowAccent,
                period: const Duration(milliseconds: 500),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}),
            
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pkUser(widget.user1['userName'], widget.user1['userImage'], widget.score1),
                _pkUser(widget.user2['userName'], widget.user2['userImage'], widget.score2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pkUser(String name, String img, int score) {
    return Column(
      children: [
        CircleAvatar(radius: 18, backgroundImage: img.isNotEmpty ? NetworkImage(img) : const NetworkImage('https://cdn-icons-png.flaticon.com/512/847/847969.png')),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
        Text("💎 $score", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}