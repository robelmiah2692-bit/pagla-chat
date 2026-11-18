import 'package:flutter/material.dart';

class SoundEffectBottomSheet extends StatelessWidget {
  final Function(String soundPath, String soundName) onSoundSelected;
  final String? activePlayingSound; // বর্তমানে যে সাউন্ডটি চলছে

  const SoundEffectBottomSheet({
    Key? key, 
    required this.onSoundSelected,
    this.activePlayingSound,
  }) : super(key: key);

  final List soundEffects = const [
    {"name": "Cheering", "path": "assets/sounds/cheering.mp3", "icon": "🎉"},
    {"name": "Laughing", "path": "assets/sounds/laugh.mp3", "icon": "😂"},
    {"name": "Clapping", "path": "assets/sounds/clapping.mp3", "icon": "👏"},
    {"name": "Drum Roll", "path": "assets/sounds/drum.mp3", "icon": "🥁"},
    {"name": "Whistle", "path": "assets/sounds/whistle.mp3", "icon": "🎶"},
    {"name": "Surprise", "path": "assets/sounds/surprise.mp3", "icon": "😲"},
    {"name": "GameOver", "path": "assets/sounds/gameover.mp3", "icon": "❌"},
    {"name": "Magic", "path": "assets/sounds/magic.mp3", "icon": "✨"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF13182C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: Colors.cyanAccent, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "🎙️ Room Sound Effects",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context), // ইউজার নিজের ইচ্ছেমতো বন্ধ করবে
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 🟢 শুধু আপনার দেখার জন্য স্ট্যাটাস (রুমের কেউ দেখবে না)
          if (activePlayingSound != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amberAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "Now Playing: $activePlayingSound 🎶",
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

          // সাউন্ড ইফেক্ট গ্রিড
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: soundEffects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              var sound = soundEffects[index] as Map<String, String>;
              bool isPlaying = activePlayingSound == sound['name'];

              return InkWell(
                onTap: () {
                  onSoundSelected(sound['path']!, sound['name']!);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    // যেটি বাজছে সেটির ব্যাকগ্রাউন্ড ও বর্ডার আলাদা কালার দেখাবে যাতে আপনি বুঝতে পারেন
                    color: isPlaying ? Colors.amber.withOpacity(0.25) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isPlaying ? Colors.amberAccent : Colors.cyanAccent.withOpacity(0.3),
                      width: isPlaying ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sound['icon']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 5),
                      Text(
                        sound['name']!,
                        style: TextStyle(
                          color: isPlaying ? Colors.amberAccent : Colors.white70, 
                          fontSize: 11, 
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}