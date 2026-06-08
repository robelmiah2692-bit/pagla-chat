import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomSettingsHandler {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required String roomId,
    required VoidCallback onToggleLock,
    required Function(String) onSetWallpaper,
    required VoidCallback onLeave,
    required VoidCallback onMinimize,
    required VoidCallback onClearChat,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0C29).withOpacity(0.95),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        side: BorderSide(color: Colors.white12, width: 1),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.9),
                const Color(0xFF0F0C29).withOpacity(1.0),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Room Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 25),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 15, bottom: 12),
                    child: Text(
                      "Free Wallpapers",
                      style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      String wallUrl =
                          "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/wallpaper-${index + 1}.jpg";
                      return GestureDetector(
                        onTap: () async {
                          try {
                            await _firestore
                                .collection('rooms')
                                .doc(roomId)
                                .update({
                              'currentWallpaper': wallUrl,
                            });
                            onSetWallpaper(wallUrl);
                          } catch (e) {
                            _showMessage(context, "Error saving wallpaper: $e");
                          }
                        },
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                            image: DecorationImage(
                              image: NetworkImage(wallUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Icon(Icons.check_circle_outline,
                              color: Colors.white38, size: 20),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildItem(isLocked ? Icons.lock : Icons.lock_open,
                        isLocked ? "Unlock" : "Lock", Colors.amber, () {
                      _handleFeaturePurchase(
                          context, roomId, "room_lock", onToggleLock);
                    }),
                    _buildItem(
                        Icons.add_photo_alternate, "Gallery", Colors.cyanAccent,
                        () async {
                      _handleFeaturePurchase(context, roomId, "wallpaper",
                          () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource
                                .gallery); // কোয়ালিটি রিমুভ করেছি কারণ নিচে কম্প্রেস হবে

                        if (image != null) {
                          try {
                            _showMessage(
                                context, "Optimizing and uploading...");

                            // কম্প্রেস লজিক
                            final compressedBytes =
                                await FlutterImageCompress.compressWithFile(
                              image.path,
                              quality: 60,
                              minWidth: 800,
                              minHeight: 800,
                            );

                            if (compressedBytes == null) return;

                            var roomDoc = await _firestore
                                .collection('rooms')
                                .doc(roomId)
                                .get();
                            String? oldWallpaperUrl =
                                roomDoc.data()?['currentWallpaper'];

                            if (oldWallpaperUrl != null &&
                                oldWallpaperUrl.contains('firebasestorage')) {
                              try {
                                await FirebaseStorage.instance
                                    .refFromURL(oldWallpaperUrl)
                                    .delete();
                              } catch (e) {
                                debugPrint("Old wallpaper delete error: $e");
                              }
                            }

                            String fileName =
                                'room_wallpapers/$roomId/${DateTime.now().millisecondsSinceEpoch}.jpg';
                            Reference storageRef =
                                FirebaseStorage.instance.ref().child(fileName);

                            // কম্প্রেসড বাইটস আপলোড
                            UploadTask uploadTask =
                                storageRef.putData(compressedBytes);
                            TaskSnapshot snapshot = await uploadTask;
                            String downloadUrl =
                                await snapshot.ref.getDownloadURL();

                            await _firestore
                                .collection('rooms')
                                .doc(roomId)
                                .update({
                              'currentWallpaper': downloadUrl,
                              'wallpaperSetAt': FieldValue.serverTimestamp(),
                            });

                            onSetWallpaper(downloadUrl);
                            _showMessage(context, "New wallpaper updated!");
                          } catch (e) {
                            _showMessage(
                                context, "Failed to update wallpaper: $e");
                          }
                        }
                      });
                    }),
                    _buildItem(
                        Icons.delete_sweep, "Clear Chat", Colors.orangeAccent,
                        () {
                      Navigator.pop(context);
                      onClearChat();
                    }),
                    _buildItem(Icons.open_in_full, "Minimize", Colors.green,
                        () {
                      // শুধু সেটিংস বটমশিটটি বন্ধ করবে
                      Navigator.pop(context);

                      // মিনিমাইজ ফাংশনটি কল করবে
                      onMinimize();
                    }),
                    _buildItem(Icons.logout, "Exit", Colors.redAccent, () {
                      // সরাসরি রুমের মেইন এক্সিট লজিক কল করুন, সেটিংস মেনু ভেতরেই হ্যান্ডেল হবে
                      onLeave();
                    }),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _handleFeaturePurchase(BuildContext context, String roomId,
      String featureType, Function onAllowed) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _showMessage(context, "Please login first!");
      return;
    }

    try {
      // ১. ইউজার ডাটা এবং রুম ডাটা আনা
      var userQuery = await _firestore
          .collection('users')
          .where(Filter.or(Filter('authUID', isEqualTo: user.uid),
              Filter('uID', isEqualTo: user.uid)))
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return;
      var userDoc = userQuery.docs.first;
      var roomRef = _firestore.collection('rooms').doc(roomId);
      var roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;
      var roomData = roomSnap.data() as Map<String, dynamic>;

      // ২. মালিকানা যাচাই
      String currentUserUID = userDoc.data()['uID'] ?? "";
      String roomOwnerId = roomData['ownerId'] ?? "";
      bool isOwner = (roomOwnerId == currentUserUID);

      // ৩. যদি মালিক হয়, তবে সে সরাসরি লক ম্যানেজ করতে পারবে (প্যাকেজ চেক ছাড়া)
      if (isOwner && featureType == "room_lock") {
        _showManageLockDialog(context, roomId, roomData);
        return;
      }

      // ৪. যদি মালিক না হয়, তবে সাধারণ প্যাকেজ চেক লজিক
      var packageData = roomData[featureType + '_package'];
      bool hasActivePackage = false;
      if (packageData != null && packageData['expiry'] != null) {
        DateTime expiry = (packageData['expiry'] as Timestamp).toDate();
        if (DateTime.now().isBefore(expiry)) hasActivePackage = true;
      }

      if (hasActivePackage) {
        onAllowed();
      } else {
        _showPurchaseDialog(context, (int hours, int diamonds) async {
          int myDiamonds = (userDoc.data()['diamonds'] ?? 0).toInt();
          if (myDiamonds >= diamonds) {
            await _firestore
                .collection('users')
                .doc(userDoc.id)
                .update({'diamonds': myDiamonds - diamonds});
            await roomRef.update({
              featureType + '_package': {
                'expiry': Timestamp.fromDate(
                    DateTime.now().add(Duration(hours: hours))),
                'boughtAt': FieldValue.serverTimestamp(),
              }
            });
            onAllowed();
          } else {
            _showMessage(context, "Insufficient Diamonds!");
          }
        });
      }
    } catch (e) {
      debugPrint("Purchase Error: $e");
    }
  }

// মালিকের জন্য আলাদা ম্যানেজ ডায়ালগ (লক/আনলক/চেঞ্জ পাস)
  static void _showManageLockDialog(
      BuildContext context, String roomId, Map<String, dynamic> roomData) {
    bool isLocked = roomData['isLocked'] ?? false;

    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F0C29),
        title: const Text("Manage Room Lock",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked)
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .update({'isLocked': false});
                  Navigator.pop(dContext);
                },
                child: const Text("Unlock Room"),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dContext);
                _showPasswordDialog(
                    context, roomId, () {}); // নতুন পাসওয়ার্ড সেট
              },
              child: Text(isLocked ? "Change Password" : "Set Password"),
            ),
          ],
        ),
      ),
    );
  }

  static void _showPasswordDialog(
      BuildContext context, String roomId, Function onConfirm) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F0C29),
        title: const Text("Set Room Password",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter 4 digit code",
            hintStyle: TextStyle(color: Colors.white24),
            counterStyle: TextStyle(color: Colors.white60),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                if (passController.text.length == 4) {
                  // এখানে ডাটাবেজে আপডেট করছি
                  try {
                    await FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .update({
                      'isLocked': true,
                      'password': passController.text,
                    });
                    Navigator.pop(dContext);
                    onConfirm(); // এটি লকের আইকন আপডেট করার জন্য
                  } catch (e) {
                    _showMessage(context, "Failed to lock: $e");
                  }
                }
              },
              child: const Text("Set")),
        ],
      ),
    );
  }

  static void _showPurchaseDialog(
      BuildContext context, Function(int, int) onBuy) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Activate Feature",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text(
            "You don't have an active package for this feature.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(dContext);
                onBuy(24, 400);
              },
              child: const Text("24 Hours (400 💎)")),
          TextButton(
              onPressed: () {
                Navigator.pop(dContext);
                onBuy(720, 9000);
              },
              child: const Text("30 Days (9000 💎)")),
        ],
      ),
    );
  }

// এটি আপনার RoomSettingsHandler ক্লাসে বসান
  static void showJoinPasswordDialog(BuildContext context, String roomId,
      String correctPassword, Function onJoinSuccess) {
    TextEditingController joinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Enter Room Password",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: joinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (joinController.text == correctPassword) {
                Navigator.pop(dContext);
                onJoinSuccess(); // পাসওয়ার্ড সঠিক হলে রুমে ঢুকবে
              } else {
                _showMessage(context, "Wrong Password!");
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  static Widget _buildItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  static void showExitDialog(
      BuildContext context, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false, // ডাটা ক্লিন হওয়ার আগে যেন বের না হতে পারে
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Exit Room?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to leave?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () async {
                // Confirm বাটনে ক্লিক করলে লজিক রান হবে
                await onConfirm();
                // লজিক শেষ হলে ডায়ালগ বন্ধ হবে
                if (Navigator.canPop(dContext)) {
                  Navigator.pop(dContext);
                }
              },
              child: const Text("Confirm",
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
