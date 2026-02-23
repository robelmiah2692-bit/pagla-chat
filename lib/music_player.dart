import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MusicPlayerPage extends StatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  List<File> musicFiles = []; // আপনার সব মিউজিক এখানে জমা হবে
  int currentIndex = -1;
  bool isPlaying = false;

  // ফোন থেকে গান সিলেক্ট করার ফাংশন
  Future<void> pickMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true, // একসাথে অনেক গান নেওয়া যাবে
    );

    if (result != null) {
      setState(() {
        musicFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Colors.black,
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
      body: Column(
        children: [
          // গানের লিস্ট
          Expanded(
            child: musicFiles.isEmpty
                ? const Center(child: Text("কোনো গান নেই, + বাটনে ক্লিক করুন", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: musicFiles.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.white70),
                      title: Text(musicFiles[index].path.split('/').last, 
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => musicFiles.removeAt(index)),
                      ),
                      onTap: () => setState(() {
                        currentIndex = index;
                        isPlaying = true;
                      }),
                    ),
                  ),
          ),
          
          // মিউজিক প্লেয়ার বার (নিচে থাকবে)
          if (currentIndex != -1) _buildBottomPlayerBar(),
        ],
      ),
    );
  }

  // প্রিমিয়াম প্লেয়ার বার
  Widget _buildBottomPlayerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.greenAccent, child: Icon(Icons.play_arrow)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              musicFiles[currentIndex].path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            onPressed: () {
              if (currentIndex > 0) setState(() => currentIndex--);
            },
          ),
          IconButton(
            icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                color: Colors.greenAccent, size: 40),
            onPressed: () => setState(() => isPlaying = !isPlaying),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () {
              if (currentIndex < musicFiles.length - 1) setState(() => currentIndex++);
            },
          ),
        ],
      ),
    );
  }
}
