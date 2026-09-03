import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/RoomLevelHelper.dart';

class RoomSettingsHandler {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required bool isOwner, // নতুন প্যারামিটার
    required bool isAdmin, // নতুন প্যারামিটার
    required String roomId,
    required VoidCallback onToggleLock,
    required Function(String) onSetWallpaper,
    required VoidCallback onLeave,
    required VoidCallback onMinimize,
    required VoidCallback onShareRoom,
    required VoidCallback onClearChat,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors
          .transparent, // ট্রান্সপারেন্ট করা হলো যাতে ভেতরের গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড সঠিকভাবে ফুটে ওঠে
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            // 🔥 আপনার পছন্দের ডায়ালগ কার্ডের সেইম আকর্ষণীয় মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
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

                // এখানে লেভেল বার বসানো হয়েছে
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists)
                      return const SizedBox();
                    var roomData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    int totalXp = roomData['totalXp'] ?? 0;
                    int level = RoomLevelHelper.calculateLevel(totalXp);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ROOM LEVEL: $level",
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              Text("${totalXp % 250} / 250 XP",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: (totalXp % 250) / 250,
                            backgroundColor: Colors.white24,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                if (isOwner || isAdmin) ...[
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
                        // আপনার আগের কোডটি এই নতুন লজিক দিয়ে রিপ্লেস করুন
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
                              _showMessage(
                                  context, "Error saving wallpaper: $e");
                            }
                          },
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(wallUrl),
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
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isOwner || isAdmin)
                      _buildItem(isLocked ? Icons.lock : Icons.lock_open,
                          isLocked ? "Unlock" : "Lock", Colors.amber, () {
                        _handleFeaturePurchase(
                            context, roomId, "room_lock", onToggleLock);
                      }),
                    if (isOwner || isAdmin)
                      _buildItem(Icons.add_photo_alternate, "Gallery",
                          Colors.cyanAccent, () async {
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
                              Reference storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(fileName);

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
                    if (isOwner || isAdmin)
                      _buildItem(
                          Icons.delete_sweep, "Clear Chat", Colors.orangeAccent,
                          () {
                        Navigator.pop(context);
                        onClearChat();
                      }),
                    _buildItem(
                      Icons.share,
                      "Share Room",
                      Colors.greenAccent,
                      () {
                        onShareRoom(); // মেইন রুম ফাইল থেকে পাঠানো onShareRoom ফাংশনটি এখানে ট্রিগার হবে
                      },
                    ),
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

// মালিকের জন্য আলাদা ম্যানেজ ডায়ালগ (লক/আনলক/চেঞ্জ পাস)
  static void _showManageLockDialog(
      BuildContext context, String roomId, Map<String, dynamic> roomData) {
    bool isLocked = roomData['isLocked'] ?? false;

    showDialog(
      context: context,
      builder: (dContext) => Dialog(
        backgroundColor: Colors
            .transparent, // ট্রান্সপারেন্ট করা হলো যাতে ভেতরের গ্রেডিয়েন্ট দেখা যায়
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // 🔥 আপনার পছন্দের সেইম মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Manage Room Lock",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              if (isLocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(roomId)
                          .update({'isLocked': false});
                      Navigator.pop(dContext);
                    },
                    child: const Text(
                      "Unlock Room",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              if (isLocked) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.5),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dContext);
                    _showPasswordDialog(
                        context, roomId, () {}); // নতুন পাসওয়ার্ড সেট
                  },
                  child: Text(
                    isLocked ? "Change Password" : "Set Password",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPasswordDialog(
      BuildContext context, String roomId, Function onConfirm) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => Dialog(
        backgroundColor: Colors
            .transparent, // ট্রান্সপারেন্ট করা হলো যাতে গ্রেডিয়েন্ট ভেসে ওঠে
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // 🔥 আপনার পছন্দের সেইম মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set Room Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter 4 digit code",
                  hintStyle: const TextStyle(color: Colors.white24),
                  counterStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dContext),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.5),
                      ),
                    ),
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
                    child: const Text(
                      "Set",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPurchaseDialog(
      BuildContext context, Function(int, int) onBuy) {
    showDialog(
      context: context,
      builder: (dContext) => Dialog(
        backgroundColor: Colors
            .transparent, // ট্রান্সপারেন্ট করা হলো যাতে গ্রেডিয়েন্ট ভেসে ওঠে
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // 🔥 আপনার পছন্দের সেইম মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Activate Feature",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "You don't have an active package for this feature.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.4),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dContext);
                      onBuy(24, 400);
                    },
                    child: const Text(
                      "24 Hours 400💎",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.purpleAccent.withOpacity(0.5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dContext);
                      onBuy(720, 9000);
                    },
                    child: const Text(
                      "30 Days 9k💎",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// এটি আপনার RoomSettingsHandler ক্লাসে বসান
  static void showJoinPasswordDialog(BuildContext context, String roomId,
      String correctPassword, Function onJoinSuccess) {
    TextEditingController joinController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => Dialog(
        backgroundColor: Colors
            .transparent, // ট্রান্সপারেন্ট করা হলো যাতে গ্রেডিয়েন্ট ভেসে ওঠে
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // 🔥 আপনার পছন্দের সেইম মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter Room Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: joinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter 4 digit password",
                  hintStyle: const TextStyle(color: Colors.white24),
                  counterStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dContext),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.cyanAccent.withOpacity(0.5),
                      ),
                    ),
                    onPressed: () {
                      if (joinController.text == correctPassword) {
                        Navigator.pop(dContext);
                        onJoinSuccess(); // পাসওয়ার্ড সঠিক হলে রুমে ঢুকবে
                      } else {
                        _showMessage(context, "Wrong Password!");
                      }
                    },
                    child: const Text(
                      "Join",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      barrierDismissible: false,
      builder: (dContext) => Dialog(
        backgroundColor: Colors
            .transparent, // ট্রান্সপারেন্ট করা হলো যাতে গ্রেডিয়েন্ট ভেসে ওঠে
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // 🔥 আপনার পছন্দের সেইম মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A), // ডিপ ব্লু
                Color(0xFF1B1A55), // মিড নাইট ব্লু
                Color(0xFF4A154B), // সফট পার্পল/ম্যাজেন্টা মিক্স
              ],
            ),
            border: Border.all(
              color: Colors.cyanAccent
                  .withOpacity(0.3), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.2),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Exit Room?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Are you sure you want to leave?",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dContext),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                    ),
                    onPressed: () async {
                      // ১. প্রথমে ডায়ালগটি বন্ধ করুন
                      Navigator.pop(dContext);

                      // ২. এরপর সেটিংস বটমশিট এবং রুম স্ক্রিন একসাথে বা পরপর রিমুভ করার জন্য মূল কন্টেক্সট ব্যবহার করুন
                      if (Navigator.canPop(context)) {
                        Navigator.pop(
                            context); // সেটিংস বটমশিট বা রুম স্ক্রিন বন্ধ
                      }
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // যদি রুম স্ক্রিন আলাদা থাকে
                      }

                      // ৩. ব্যাকগ্রাউন্ডে ক্লিনিং এবং আগোরা রিলিজ করুন
                      await onConfirm();
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
