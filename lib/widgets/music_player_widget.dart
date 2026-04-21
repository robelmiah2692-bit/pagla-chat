import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class MusicPlayerWidget extends StatefulWidget {
  final Function(String path) onMusicSelect; 
  final Function(double volume) onVolumeChange; 

  const MusicPlayerWidget({
    super.key, 
    required this.onMusicSelect, 
    required this.onVolumeChange, 
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  List<String> savedMusicNames = [];
  List<String> savedMusicPaths = [];
  double _currentVolume = 0.5; 

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
      savedMusicPaths = prefs.getStringList('my_music_paths') ?? [];
    });
  }

  // --- এরর মুক্ত pickMusic মেথড ---
  Future<void> pickMusic() async {
    try {
      // সরাসরি FilePicker.platform.pickFiles কল করার পরিবর্তে 
      // রেজাল্টটি আগে নিয়ে চেক করা হচ্ছে।
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          for (var file in result.files) {
            if (file.path != null && !savedMusicPaths.contains(file.path)) {
              savedMusicNames.add(file.name);
              savedMusicPaths.add(file.path!);
            }
          }
        });
        await prefs.setStringList('my_music_names', savedMusicNames);
        await prefs.setStringList('my_music_paths', savedMusicPaths);
      }
    } catch (e) {
      debugPrint("File Picker Error: $e");
    }
  }

  Future<void> deleteMusic(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedMusicNames.removeAt(index);
      savedMusicPaths.removeAt(index);
    });
    await prefs.setStringList('my_music_names', savedMusicNames);
    await prefs.setStringList('my_music_paths', savedMusicPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550, 
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.white54, size: 20),
                  Expanded(
                    child: Slider(
                      value: _currentVolume,
                      activeColor: Colors.greenAccent,
                      inactiveColor: Colors.white10,
                      onChanged: (value) {
                        setState(() {
                          _currentVolume = value;
                        });
                        widget.onVolumeChange(value * 100); 
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white54, size: 20),
                ],
              ),
            ),

            const TabBar(
              tabs: [
                Tab(text: "Hridoy's Library"),
                Tab(text: "My Gallery"),
              ],
              labelColor: Colors.greenAccent,
              indicatorColor: Colors.greenAccent,
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Default Library
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

                  // Tab 2: Local Gallery
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
                            ? const Center(child: Text("খালি", style: TextStyle(color: Colors.white24)))
                            : ListView.builder(
                                itemCount: savedMusicNames.length,
                                itemBuilder: (context, index) => ListTile(
                                  leading: const Icon(Icons.audio_file, color: Colors.white54),
                                  title: Text(savedMusicNames[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => deleteMusic(index),
                                  ),
                                  onTap: () {
                                    widget.onMusicSelect(savedMusicPaths[index]);
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