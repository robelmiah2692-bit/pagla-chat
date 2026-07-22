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

  // এক ক্লিকে একাধিক গান সিলেক্ট করে গ্যালারিতে এড করার ফাংশন
  Future<void> pickMusic() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'ogg'],
        allowMultiple: true, // একসাথে একাধিক গান সিলেক্ট করার সুবিধা
        withReadStream: true,
        withData: false, 
      );

      if (result != null && result.files.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        
        bool addedNew = false;
        setState(() {
          for (var file in result.files) {
            if (file.path != null && !savedMusicPaths.contains(file.path)) {
              savedMusicNames.add(file.name);
              savedMusicPaths.add(file.path!);
              addedNew = true;
            }
          }
        });

        if (addedNew) {
          await prefs.setStringList('my_music_names', savedMusicNames);
          await prefs.setStringList('my_music_paths', savedMusicPaths);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${result.files.length} টি নতুন গান যুক্ত হয়েছে!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
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
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          
          // ভলিউম কন্ট্রোল স্লাইডার
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

          // টাইটেল: My Gallery
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "My Gallery",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // লোকাল মিউজিক গ্যালারি লিস্ট
          Expanded(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  title: const Text("Add Local Music (Multi-Select)", style: TextStyle(color: Colors.greenAccent)),
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
                            title: Text(
                              savedMusicNames[index], 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis, 
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
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
          ),
        ],
      ),
    );
  }
}