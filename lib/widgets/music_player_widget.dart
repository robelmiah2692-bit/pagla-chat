import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class MusicPlayerWidget extends StatefulWidget {
  final Function(String path) onMusicSelect; 

  const MusicPlayerWidget({super.key, required this.onMusicSelect});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  List<String> savedMusicNames = [];

  // ১. আপনার দেওয়া ২০টি গানের লাইব্রেরি (লিঙ্কসহ)
  final List<Map<String, String>> hridoyDefaultLibrary = [
    {"name": "Bangla Folk Fusion", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"},
    {"name": "Baul Soul Mix", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"},
    {"name": "Dhaka City Beat", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"},
    {"name": "Amar Poran Jaha Chay", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"},
    {"name": "Lalon Giti Mix", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3"},
    {"name": "HINDI: Bollywood Romance", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3"},
    {"name": "HINDI: Desi Party Beat", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3"},
    {"name": "HINDI: Sufi Night", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3"},
    {"name": "HINDI: Chill Vibes", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"},
    {"name": "HINDI: Emotional Sad", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3"},
    {"name": "Midnight Melody", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3"},
    {"name": "Morning Vibes", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3"},
    {"name": "Evening Raga", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3"},
    {"name": "Rainy Day Song", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3"},
    {"name": "Romantic Night", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3"},
    {"name": "Slow Rock Bangla", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3"},
    {"name": "Acoustic Mix", "url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3"},
    {"name": "Fast EDM Mix", "url": "https://i.cloudup.com/S6pW9Oog7T.mp3"},
    {"name": "Bengali Chill Mix", "url": "https://i.cloudup.com/qE9733Y9U1.mp3"},
    {"name": "Adda Time Special", "url": "https://i.cloudup.com/0F7E0X3N0Y.mp3"},
  ];

  @override
  void initState() {
    super.initState();
    loadMusicList();
  }

  Future<void> loadMusicList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedMusicNames = prefs.getStringList('my_music_names') ?? [];
    });
  }

  Future<void> pickMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!savedMusicNames.contains(file.name)) {
            savedMusicNames.add(file.name);
          }
        }
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_music_names', savedMusicNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: DefaultTabController(
        length: 2, // ২টা ট্যাব: লাইব্রেরি এবং ইউজারের গান
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            
            const TabBar(
              tabs: [
                Tab(text: "Hridoy's Playlist"),
                Tab(text: "My Songs"),
              ],
              labelColor: Colors.greenAccent,
              indicatorColor: Colors.greenAccent,
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // ট্যাব ১: ২০টি ডিফল্ট গান
                  ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: hridoyDefaultLibrary.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Text("${index + 1}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      ),
                      title: Text(hridoyDefaultLibrary[index]["name"]!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                      onTap: () {
                        widget.onMusicSelect(hridoyDefaultLibrary[index]["url"]!);
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // ট্যাব ২: ইউজারের নিজের গান (APK-এর জন্য)
                  Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                        title: const Text("Add Local Music", style: TextStyle(color: Colors.greenAccent)),
                        onTap: pickMusic,
                      ),
                      const Divider(color: Colors.white10),
                      Expanded(
                        child: savedMusicNames.isEmpty
                            ? const Center(child: Text("এখনও কোনো গান যোগ করেননি", style: TextStyle(color: Colors.white24)))
                            : ListView.builder(
                                itemCount: savedMusicNames.length,
                                itemBuilder: (context, index) => ListTile(
                                  leading: const Icon(Icons.audio_file, color: Colors.white54),
                                  title: Text(savedMusicNames[index], style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  onTap: () {
                                    widget.onMusicSelect(savedMusicNames[index]);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
