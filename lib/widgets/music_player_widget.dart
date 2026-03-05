import 'package:flutter/foundation.dart';
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
  late AudioPlayer _localAudioPlayer;

  @override
  void initState() {
    super.initState();
    // রুম থেকে আসা মেইন প্লেয়ার ব্যবহার করা হচ্ছে যাতে সাউন্ড রুমে শোনা যায়
    _localAudioPlayer = widget.audioPlayer ?? AudioPlayer();
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
      withData: kIsWeb,
    );

    if (result != null) {
      List<String> newItems = [];
      for (var file in result.files) {
        if (kIsWeb) {
          if (file.name != null) newItems.add(file.name);
        } else {
          if (file.path != null) newItems.add(file.path!);
        }
      }

      if (newItems.isNotEmpty) {
        setState(() {
          savedMusicPaths.addAll(newItems);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('my_music', savedMusicPaths);
      }
    }
  }

  Future<void> deleteMusic(int index) async {
    setState(() {
      if (currentIndex == index) {
        currentIndex = -1;
        isPlaying = false;
        _localAudioPlayer.stop();
      }
      savedMusicPaths.removeAt(index);
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
        title: const Text("Music Store", 
          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
                      String path = savedMusicPaths[index];
                      String fileName = path.split('/').last.split('\\').last;
                      
                      return ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.cyanAccent),
                        title: Text(fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                          onPressed: () => deleteMusic(index),
                        ),
                        onTap: () async {
                          setState(() {
                            currentIndex = index;
                            isPlaying = true;
                          });

                          try {
                            // ✅ মেইন প্লেয়ারের মাধ্যমে গান প্লে করা
                            await _localAudioPlayer.play(DeviceFileSource(path));
                            
                            // 🔥 ফিক্স: ১০০ মিলিসেকেন্ড ওয়েট করা যাতে VoiceRoom স্টেট আপডেট করতে পারে
                            await Future.delayed(const Duration(milliseconds: 100));

                            if(context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Error playing: $e");
                          }
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
    String currentPath = savedMusicPaths[currentIndex];
    String currentFileName = currentPath.split('/').last.split('\\').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
              backgroundColor: Colors.greenAccent, 
              child: Icon(Icons.music_video, color: Colors.black)),
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
                await _localAudioPlayer.pause();
              } else {
                await _localAudioPlayer.resume();
              }
              setState(() {
                isPlaying = !isPlaying;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => setState(() => currentIndex = -1),
          )
        ],
      ),
    );
  }
}
