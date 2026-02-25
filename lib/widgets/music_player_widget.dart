import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<String> savedMusicPaths = [];
  int currentIndex = -1;
  bool isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadMusicList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
      if (currentIndex == index) {
        currentIndex = -1;
        _audioPlayer.stop();
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_music', savedMusicPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Music Store", style: TextStyle(color: Colors.greenAccent)),
        actions: [
          IconButton(
            onPressed: pickMusic,
            icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent, size: 30),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: savedMusicPaths.isEmpty
                ? const Center(
                    child: Text("কোনো গান নেই, + বাটনে ক্লিক করুন",
                        style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: savedMusicPaths.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.white70),
                      title: Text(savedMusicPaths[index].split('/').last,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => deleteMusic(index),
                      ),
                      onTap: () {
                        // ভয়েস রুমে ডাটা পাঠানো
                        Navigator.pop(context, {
                          'path': savedMusicPaths[index],
                          'name': savedMusicPaths[index].split('/').last,
                        });
                      },
                    ),
                  ),
          ),
          if (currentIndex != -1) _buildBottomPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildBottomPlayerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Colors.greenAccent, child: Icon(Icons.play_arrow)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              savedMusicPaths[currentIndex].split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.greenAccent,
              size: 40,
            ),
            onPressed: () async {
              if (isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.resume();
              }
              setState(() {
                isPlaying = !isPlaying;
              });
            },
          ),
        ],
      ),
    );
  }
}
