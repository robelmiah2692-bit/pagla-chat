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
  List<String> savedMusicNames = []; // ওয়েবে আমরা নামগুলো সেভ রাখবো

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
    // ওয়েবের জন্য pickFiles এ 'withData: true' থাকা জরুরি নয়, কিন্তু ভালো।
    // ওয়েবে পাথ পাওয়া যায় না, তাই আমরা 'name' এবং মেমোরি রেফারেন্স নিয়ে কাজ করি।
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          // ওয়েবে পাথ নাল থাকে, তাই আমরা ফাইলের নাম ব্যবহার করছি
          String fileName = file.name;
          if (!savedMusicNames.contains(fileName)) {
            savedMusicNames.add(fileName);
          }
        }
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_music_names', savedMusicNames);
    }
  }

  Future<void> deleteMusic(int index) async {
    setState(() {
      savedMusicNames.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_music_names', savedMusicNames);
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
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
            child: savedMusicNames.isEmpty
                ? const Center(
                    child: Text("কোনো গান নেই, + বাটনে ক্লিক করুন", 
                    style: TextStyle(color: Colors.white24, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: savedMusicNames.length,
                    itemBuilder: (context, index) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.music_note, color: Colors.cyanAccent),
                      ),
                      title: Text(savedMusicNames[index], // সরাসরি নাম দেখাচ্ছি
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        onPressed: () => deleteMusic(index),
                      ),
                      onTap: () {
                        // ওয়েবে পাথের বদলে আমরা নামটা পাঠাচ্ছি
                        widget.onMusicSelect(savedMusicNames[index]);
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
