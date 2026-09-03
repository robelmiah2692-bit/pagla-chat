import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

  // 🛠️ ফোনের কমন ফোল্ডারগুলো থেকে অডিও ফাইল খুঁজে বের করার পদ্ধতি
  Future<void> openPhoneMusicPicker() async {
    PermissionStatus status;
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // অ্যান্ড্রয়েড ১৩ বা উচ্চতর ভার্সনের জন্য READ_MEDIA_AUDIO রিকোয়েস্ট করতে হবে
        status = await Permission.audio.request();
      } else {
        // পুরনো ভার্সনের জন্য স্টোরেজ পারমিশন
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.storage.request();
    }

    // যদি পারমিশন না দেয়, তবে সরাসরি সেটিংসে যাওয়ার অপশন বা মেসেজ দেখাবে
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        openAppSettings(); // ইউজার পারমিশন ব্লক করে রাখলে সরাসরি সেটিংস ওপেন করবে
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Audio/storage permission is required to load songs. Please grant permission."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // আপনার দেওয়া তালিকা অনুযায়ী সকল কমন ফোল্ডারের পাথ
    List<File> audioFiles = [];
    Set<String> scannedPaths = {}; // ডুপ্লিকেট এড়ানোর জন্য

    try {
      final directories = [
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Music'),
        Directory('/storage/emulated/0/Ringtones'),
        Directory('/storage/emulated/0/Recordings'),
        Directory('/storage/emulated/0/SoundRecorder'),
        Directory('/storage/emulated/0/Recorder'),
        Directory('/storage/emulated/0/ShareIt/audio'),
        Directory('/storage/emulated/0/Shareit'),
        Directory('/storage/emulated/0/Bluetooth'),
        Directory('/storage/emulated/0/QuickShare'),
        Directory('/storage/emulated/0/Telegram/Telegram Audio'),
        Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Audio'),
        Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Audio'),
        Directory('/storage/emulated/0/Download/VidMate'),
        Directory('/storage/emulated/0/Vidmate/download'),
        Directory('/storage/emulated/0/imo/imo_savelist'),
      ];

      for (var dir in directories) {
        if (dir.existsSync()) {
          try {
            final list = dir.listSync(recursive: true);
            for (var entity in list) {
              if (entity is File) {
                String path = entity.path;
                String lowerPath = path.toLowerCase();
                
                if (lowerPath.endsWith('.mp3') || 
                    lowerPath.endsWith('.wav') || 
                    lowerPath.endsWith('.m4a') || 
                    lowerPath.endsWith('.aac') ||
                    lowerPath.endsWith('.ogg') ||
                    lowerPath.endsWith('.flac')) {
                  
                  if (!scannedPaths.contains(path)) {
                    scannedPaths.add(path);
                    audioFiles.add(entity);
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error reading dir ${dir.path}: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error finding audio files: $e");
    }

    if (audioFiles.isEmpty) {
      if (mounted) {
        // যদি সরাসরি ফোল্ডারে না পাওয়া যায়, তবে ম্যানুয়াল পাথ বা লিংক দেওয়ার অপশন ডায়ালগ ওপেন হবে
        _showManualPathDialog();
      }
      return;
    }

    // ৩. গান নির্বাচনের জন্য পপআপ ডায়ালগ
    Set<String> tempSelectedPaths = {};
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                title: Text("Select songs from phone (${audioFiles.length} found)", style: const TextStyle(color: Colors.cyanAccent, fontSize: 15)),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView.builder(
                    itemCount: audioFiles.length,
                    itemBuilder: (context, index) {
                      final file = audioFiles[index];
                      final filePath = file.path;
                      final fileName = filePath.split('/').last;
                      final isAlreadyInGallery = savedMusicPaths.contains(filePath);
                      final isSelected = tempSelectedPaths.contains(filePath) || isAlreadyInGallery;

                      return CheckboxListTile(
                        value: isSelected,
                        enabled: !isAlreadyInGallery,
                        title: Text(fileName, style: TextStyle(color: isAlreadyInGallery ? Colors.white30 : Colors.white, fontSize: 13)),
                        subtitle: Text(filePath, style: const TextStyle(color: Colors.white24, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        activeColor: Colors.greenAccent,
                        checkColor: Colors.black,
                        onChanged: (bool? value) {
                          if (!isAlreadyInGallery) {
                            setStateDialog(() {
                              if (value == true) {
                                tempSelectedPaths.add(filePath);
                              } else {
                                tempSelectedPaths.remove(filePath);
                              }
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Cancel", style: TextStyle(color: Colors.redAccent))
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                    onPressed: tempSelectedPaths.isEmpty ? null : () async {
                      final prefs = await SharedPreferences.getInstance();
                      int addedCount = 0;

                      setState(() {
                        for (var path in tempSelectedPaths) {
                          if (!savedMusicPaths.contains(path)) {
                            String name = path.split('/').last;
                            savedMusicNames.add(name);
                            savedMusicPaths.add(path);
                            addedCount++;
                          }
                        }
                      });

                      if (addedCount > 0) {
                        await prefs.setStringList('my_music_names', savedMusicNames);
                        await prefs.setStringList('my_music_paths', savedMusicPaths);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("$addedCount Song Added Sucssesfuly।"), backgroundColor: Colors.green)
                          );
                        }
                      }
                      Navigator.pop(context);
                    },
                    child: const Text("Add", style: TextStyle(color: Colors.black)),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
  // ফাইলে গান না পেলে সরাসরি নাম ও পাথ লিখে যোগ করার ব্যাকআপ ডায়ালগ
  void _showManualPathDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Add Localy ", style: TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Songs Name", labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "File", labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              if (nameController.text.isNotEmpty && pathController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  savedMusicNames.add(nameController.text);
                  savedMusicPaths.add(pathController.text);
                });
                await prefs.setStringList('my_music_names', savedMusicNames);
                await prefs.setStringList('my_music_paths', savedMusicPaths);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
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

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Pagla Music Home🎼📢",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.greenAccent),
                  title: const Text("Add Local Music🎶", style: TextStyle(color: Colors.greenAccent)),
                  onTap: openPhoneMusicPicker,
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: savedMusicNames.isEmpty
                      ? const Center(child: Text("No Music", style: TextStyle(color: Colors.white24)))
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