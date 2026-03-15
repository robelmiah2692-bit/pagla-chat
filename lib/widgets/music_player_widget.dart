import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class MusicPlayerWidget extends StatefulWidget {
  final Function(String path) onMusicSelect; // গান সিলেক্ট করলে রুমে পাঠানোর জন্য

  const MusicPlayerWidget({super.key, required this.onMusicSelect});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  List<String> savedMusicPaths = [];

  @override
  void initState() {
    super.initState();
    loadMusicList();
  }

  Future<void> loadMusicList() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedMusicPaths = prefs.getStringList('my_music') ?? [];
    });
  }

  Future<void> pickMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      List<String> newPaths = result.paths.whereType<String>().toList();
      setState(() {
        savedMusicPaths.addAll(newPaths);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_music', savedMusicPaths);
    }
  }

  Future<void> deleteMusic(int index) async {
    setState(() {
      savedMusicPaths.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_music', savedMusicPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // ড্র্যাগ ইন্ডিকেটর
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          // টপ বার এবং + বাটন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Music Store", 
                  style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: pickMusic,
                  icon: const Icon(Icons.add_circle, color: Colors.greenAccent, size: 35),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: savedMusicPaths.isEmpty
                ? const Center(
                    child: Text("কোনো গান নেই, + বাটনে ক্লিক করুন", 
                    style: TextStyle(color: Colors.white24, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: savedMusicPaths.length,
                    itemBuilder: (context, index) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.1), // white05 ফিক্স করা হয়েছে
                        child: const Icon(Icons.music_note, color: Colors.cyanAccent),
                      ),
                      title: Text(savedMusicPaths[index].split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
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
    );
  }
}
