import 'package:flutter/foundation.dart'; // kIsWeb এর জন্য
// dart:io সরাসরি ইম্পোর্ট না করে কন্ডিশনাল ইম্পোর্ট করা ভালো
// তবে এখানে আমরা kIsWeb চেক দিয়ে এরর হ্যান্ডেল করব।
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerPage extends StatefulWidget {
  final AudioPlayer? audioPlayer;
  final bool? isDragging;
  
  const MusicPlayerPage({super.key, this.audioPlayer, this.isDragging});

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
    // ফাইল পিকার ওয়েবেও কাজ করে, তবে পাথের বদলে বাইটস ব্যবহার হয়
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      // ওয়েবে পাথ থাকে না, তাই কন্ডিশনাল চেক
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
                    itemBuilder: (context, index) {
                      // পাথের এরর এড়াতে split('/') এর আগে চেক
                      String fileName = savedMusicPaths[index].contains('/') 
                          ? savedMusicPaths[index].split('/').last 
                          : savedMusicPaths[index].split('\\').last;
                      
                      return ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.white70),
                        title: Text(fileName,
                            style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => deleteMusic(index),
                        ),
                        onTap: () {
                          Navigator.pop(context, {
                            'path': savedMusicPaths[index],
                            'name': fileName,
                          });
                        },
                      );
                    },
                  ),
          ),
          if (currentIndex != -1) _buildBottomPlayerBar(),
        ],
      ),
    );
  }

  Widget _buildBottomPlayerBar() {
    String currentFileName = savedMusicPaths[currentIndex].contains('/') 
        ? savedMusicPaths[currentIndex].split('/').last 
        : savedMusicPaths[currentIndex].split('\\').last;

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
              currentFileName,
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
