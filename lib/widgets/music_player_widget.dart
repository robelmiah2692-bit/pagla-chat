import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  final AudioPlayer? audioPlayer;
  const MusicPlayerPage({super.key, this.audioPlayer});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
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
      setState(() => savedMusicPaths.addAll(newPaths));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_music', savedMusicPaths);
    }
  }

  Future<void> deleteMusic(int index) async {
    setState(() => savedMusicPaths.removeAt(index));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_music', savedMusicPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Music Store", style: TextStyle(color: Colors.greenAccent)),
        actions: [
          IconButton(
            onPressed: pickMusic,
            icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 30),
          )
        ],
      ),
      body: savedMusicPaths.isEmpty
          ? const Center(child: Text("কোনো গান নেই, + বাটনে ক্লিক করুন", style: TextStyle(color: Colors.white24)))
          : ListView.builder(
              itemCount: savedMusicPaths.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.music_note, color: Colors.cyanAccent),
                title: Text(savedMusicPaths[index].split('/').last,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => deleteMusic(index),
                ),
                onTap: () {
                  // 🔥 এখান থেকে ডাটা নিয়ে বের হয়ে যাবে
                  Navigator.pop(context, {
                    'path': savedMusicPaths[index],
                  });
                },
              ),
            ),
    );
  }
}
