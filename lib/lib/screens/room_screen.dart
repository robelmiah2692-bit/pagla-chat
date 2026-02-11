import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/seat_widget.dart';
import '../widgets/action_menu.dart';

class VoiceRoomScreen extends StatefulWidget {
  const VoiceRoomScreen({super.key});

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> {
  // ২০টি সিটের জন্য লিস্ট (বাস্তবে ডাটাবেস থেকে আসবে)
  final int totalSeats = 20;

  // নিচ থেকে অ্যাকশন মেনু (Music, Video, PK) ওপেন করার ফাংশন
  void _openActionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomActionMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundImage), // আপনার সেই HD ব্যাকগ্রাউন্ড
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- ১. ইউটিউব প্লেয়ার এরিয়া (Top) ---
              Container(
                height: 180,
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      const Text("ইউটিউব ভিডিও সিঙ্ক এরিয়া", style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),

              // --- ২. ২০টি রাজকীয় সিট (Grid) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.builder(
                    itemCount: totalSeats,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // প্রতি লাইনে ৫টি করে সিট
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${index + 1} নং সিটে আপনি বসলেন!")),
                          );
                        },
                        child: SeatWidget(index: index, isSpeaking: index == 0),
                      );
                    },
                  ),
                ),
              ),

              // --- ৩. নিচের মেসেজ ও অ্যাকশন বার ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                color: Colors.black45,
                child: Row(
                  children: [
                    // চ্যাট ইনপুট
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "বলুন কিছু...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // অ্যাকশন মেনু বাটন (Music, Video, Games এর জন্য)
                    GestureDetector(
                      onTap: _openActionMenu,
                      child: CircleAvatar(
                        backgroundColor: AppConstants.accentColor,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // গিফট বাটন
                    const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
