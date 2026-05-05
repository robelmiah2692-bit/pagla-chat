import 'package:flutter/material.dart';
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
                            source: ImageSource.gallery, imageQuality: 70);

                        if (image != null) {
                          try {
                            _showMessage(context, "Uploading wallpaper...");
                            
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

                            File file = File(image.path);
                            String fileName = 'room_wallpapers/$roomId/${DateTime.now().millisecondsSinceEpoch}.jpg';
                            Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

                            UploadTask uploadTask = storageRef.putFile(file);
                            TaskSnapshot snapshot = await uploadTask;
                            String downloadUrl = await snapshot.ref.getDownloadURL();

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
                            _showMessage(context, "Failed to update wallpaper: $e");
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
                      Navigator.pop(context);
                      onMinimize();
                    }),
                    _buildItem(Icons.logout, "Exit", Colors.redAccent, () {
                      Navigator.pop(context);
                      _showExitDialog(context, onLeave);
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
    
    // বটম শীট বন্ধ করা যাতে ডায়ালগ দেখা যায়
    Navigator.of(context).pop();

    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // আপনার ডাটাবেস অনুযায়ী authUID দিয়ে ইউজার খুঁজে বের করা
      var userQuery = await _firestore
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showMessage(context, "User profile not found!");
        return;
      }

      var userDoc = userQuery.docs.first;
      var userRef = userDoc.reference;

      var roomRef = _firestore.collection('rooms').doc(roomId);
      var roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;

      var roomData = roomSnap.data();
      var packageData = roomData?[featureType + '_package'];
      bool hasActivePackage = false;

      if (packageData != null && packageData['expiry'] != null) {
        DateTime expiry = (packageData['expiry'] as Timestamp).toDate();
        if (DateTime.now().isBefore(expiry)) {
          hasActivePackage = true;
        }
      }

      if (hasActivePackage) {
        if (featureType == "room_lock") {
          _showPasswordDialog(context, onAllowed);
        } else {
          onAllowed();
        }
      } else {
        _showPurchaseDialog(context, (int hours, int diamonds) async {
          int myDiamonds = userDoc.data()['diamonds'] ?? 0;

          if (myDiamonds >= diamonds) {
            // ডায়মন্ড কাটা এবং প্যাকেজ আপডেট করা
            await userRef.update({'diamonds': myDiamonds - diamonds});
            await roomRef.update({
              featureType + '_package': {
                'expiry': Timestamp.fromDate(
                    DateTime.now().add(Duration(hours: hours))),
                'boughtAt': FieldValue.serverTimestamp(),
              }
            });

            if (featureType == "room_lock") {
              _showPasswordDialog(context, onAllowed);
            } else {
              onAllowed();
            }
          } else {
            _showMessage(context, "Insufficient Diamonds!");
          }
        });
      }
    } catch (e) {
      debugPrint("Purchase Error: $e");
    }
  }

  static void _showPasswordDialog(BuildContext context, Function onConfirm) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
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
              onPressed: () {
                if (passController.text.length == 4) {
                  Navigator.pop(dContext);
                  onConfirm();
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
        content: const Text("You don't have an active package for this feature.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(dContext);
                onBuy(24, 200);
              },
              child: const Text("24 Hours (200 💎)")),
          TextButton(
              onPressed: () {
                Navigator.pop(dContext);
                onBuy(720, 3500);
              },
              child: const Text("30 Days (3500 💎)")),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2))
    );
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

  static void _showExitDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Exit Room?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to leave the room?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(dContext);
                onConfirm();
              },
              child: const Text("Confirm",
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}