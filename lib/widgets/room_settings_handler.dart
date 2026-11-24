
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/RoomLevelHelper.dart';

class RoomSettingsHandler {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static const List<String> _freeWallpaperTitles = [
    "Ocean Mist",
    "Neon Pulse",
    "Royal Dusk",
  ];

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
            // 🔥 আপনার পছন্দের ডায়ালগ কার্ডের সেইম আকর্ষণীয় মিক্সড কালার গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
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
                  .withOpacity(0.35), // চারপাশের গ্লোয়িং বর্ডার
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.22),
                blurRadius: 25,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.22),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D top handle pill
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Colors.purpleAccent],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3D Room Settings Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Colors.cyanAccent, Colors.amberAccent],
                  ).createShader(bounds),
                  child: const Text(
                    "Room Settings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 🔥 3D Room Level Bar
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox();
                    }
                    var roomData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    int totalXp = roomData['totalXp'] ?? 0;
                    int level = RoomLevelHelper.calculateLevel(totalXp);
                    double progress = ((totalXp % 250) / 250).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.45),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.12),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orangeAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.4),
                                      offset: const Offset(0, 2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "ROOM LEVEL: $level",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              Text(
                                "${totalXp % 250} / 250 XP",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 9,
                                backgroundColor: Colors.transparent,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 🔥 Free Wallpapers (নামসহ + 3D কার্ড)
                if (isOwner || isAdmin) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 10),
                      child: Text(
                        "Free Wallpapers",
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .snapshots(),
                    builder: (context, wallSnap) {
                      String activeWallpaper = '';
                      if (wallSnap.hasData && wallSnap.data!.exists) {
                        final wallData =
                            wallSnap.data!.data() as Map<String, dynamic>?;
                        activeWallpaper =
                            (wallData?['currentWallpaper'] ?? '').toString();
                      }

                      return SizedBox(
                        height: 114,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            // লোকাল অ্যাসেট পাথ (অপরিবর্তিত)
                            String wallPath =
                                "assets/images/wallpaper-${index + 1}.webp";
                            String wallTitle = _freeWallpaperTitles[index];
                            bool isSelectedWall = activeWallpaper == wallPath;

                            return GestureDetector(
                              onTap: () async {
                                try {
                                  await _firestore
                                      .collection('rooms')
                                      .doc(roomId)
                                      .update({
                                    'currentWallpaper': wallPath,
                                  });
                                  onSetWallpaper(wallPath);
                                } catch (e) {
                                  _showMessage(
                                      context, "Error saving wallpaper: $e");
                                }
                              },
                              child: Container(
                                width: 82,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelectedWall
                                        ? Colors.cyanAccent
                                        : Colors.white30,
                                    width: isSelectedWall ? 2.0 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelectedWall
                                          ? Colors.cyanAccent.withOpacity(0.35)
                                          : Colors.black.withOpacity(0.55),
                                      offset: const Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        wallPath,
                                        fit: BoxFit.cover,
                                      ),
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4, horizontal: 4),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.88),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          child: Text(
                                            wallTitle,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Icon(
                                          isSelectedWall
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          color: isSelectedWall
                                              ? Colors.cyanAccent
                                              : Colors.white54,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // 🔥 3D Seat Layout Settings
                if (isOwner || isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 6, top: 4, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Seat Layout Settings",
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int layoutCountVal = 10;
                      int roomLvlVal = 1;
                      Map<String, dynamic> roomData = {};

                      if (snapshot.hasData && snapshot.data!.exists) {
                        roomData =
                            snapshot.data!.data() as Map<String, dynamic>;

                        var rawLayout = roomData['seatLayoutCount'] ?? 10;
                        if (rawLayout is int) {
                          layoutCountVal = rawLayout;
                        } else if (rawLayout is String) {
                          layoutCountVal = int.tryParse(rawLayout) ??
                              (rawLayout == 'video_10' ? 101 : 10);
                        }

                        int totalXp = roomData['totalXp'] ?? 0;
                        roomLvlVal = RoomLevelHelper.calculateLevel(totalXp);
                      }

                      bool isLayoutUnlocked(dynamic layoutCount) {
                        int countVal = 10;
                        if (layoutCount is int) {
                          countVal = layoutCount;
                        } else if (layoutCount is String) {
                          countVal = int.tryParse(layoutCount) ??
                              (layoutCount == 'video_10' ? 101 : 10);
                        }

                        if (countVal == 10) return true;
                        if (countVal == 101 && roomLvlVal >= 2)
                          return true; // রুম লেভেল ২ হলে Video 10 আনলক হবে
                        if (countVal == 2 && roomLvlVal >= 6) return true;
                        if (countVal == 12 && roomLvlVal >= 10) return true;
                        if (countVal == 18 && roomLvlVal >= 20) return true;
                        if (countVal == 20 && roomLvlVal >= 40) return true;

                        var packageData =
                            roomData['seat_layout_${countVal}_package'];
                        if (packageData != null &&
                            packageData['expiry'] != null) {
                          DateTime expiry =
                              (packageData['expiry'] as Timestamp).toDate();
                          if (DateTime.now().isBefore(expiry)) {
                            return true;
                          }
                        }
                        return false;
                      }

                      Widget buildLayoutButton(
                          dynamic layoutCount, String buttonText) {
                        bool isSelected = layoutCountVal == layoutCount;
                        bool unlocked = isLayoutUnlocked(layoutCount);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () async {
                                if (unlocked) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(roomId)
                                        .update({
                                      'seatLayoutCount': layoutCount,
                                    });
                                  } catch (e) {
                                    print("Error updating layout: $e");
                                  }
                                } else {
                                  _showSeatPurchaseDialog(
                                      context, roomId, layoutCount, roomData);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFFE082),
                                            Colors.amber,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.14),
                                            Colors.white.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.amberAccent
                                        : Colors.white24,
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.orange.withOpacity(0.85)
                                          : Colors.black.withOpacity(0.65),
                                      offset: const Offset(0, 3.5),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.amber.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.35),
                                      offset: const Offset(0, 5),
                                      blurRadius: 7,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        buttonText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (!unlocked) ...[
                                      const SizedBox(width: 3),
                                      const Icon(Icons.lock,
                                          size: 13, color: Colors.redAccent),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildLayoutButton(2, "2 Seats"),
                                buildLayoutButton(10, "10 Seats"),
                                buildLayoutButton(12, "12 Seats"),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildLayoutButton(101, "Video 10"),
                                buildLayoutButton(18, "15 Seats"),
                                buildLayoutButton(20, "20 Seats"),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                ],

                // 🔥 নিচের 3D অ্যাকশন বাটনগুলো
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isOwner || isAdmin)
                      _build3DActionButton(
                        icon: isLocked ? Icons.lock : Icons.lock_open,
                        label: isLocked ? "Unlock" : "Lock",
                        color: Colors.amber,
                        onTap: () {
                          _handleFeaturePurchase(
                              context, roomId, "room_lock", onToggleLock);
                        },
                      ),
                    if (isOwner || isAdmin)
                      _build3DActionButton(
                        icon: Icons.color_lens,
                        label: "Themes",
                        color: Colors.purpleAccent,
                        onTap: () {
                          // গ্যালারি লজিক বাদ দিয়ে নতুন থিমস ট্যাব/ডায়ালগ ওপেন করার ফাংশন
                          _showThemesDialog(context, roomId, onSetWallpaper);
                        },
                      ),
                    if (isOwner || isAdmin)
                      _build3DActionButton(
                        icon: Icons.delete_sweep,
                        label: "Clear Chat",
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.pop(context);
                          onClearChat();
                        },
                      ),
                    _build3DActionButton(
                      icon: Icons.share,
                      label: "Share Room",
                      color: Colors.greenAccent,
                      onTap: () {
                        onShareRoom(); // মেইন রুম ফাইল থেকে পাঠানো onShareRoom ফাংশনটি এখানে ট্রিগার হবে
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _build3DActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.28),
                  color.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.65), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  offset: const Offset(0, 3.5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  offset: const Offset(0, 6),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  static void _showThemesDialog(BuildContext context, String roomId,
      Function(String) onSetWallpaper) async {
    // প্রতিটি থিমের সাথে লোকাল অ্যাসেট পাথ যুক্ত করা হয়েছে
    final List<Map<String, dynamic>> wallpapers = [
      {
        'name': 'dreem night',
        'url': 'assets/images/wallpaper-1.webp',
        'price': 5000,
      },
      
      {
        'name': 'dreem cuple',
        'url': 'assets/images/arvi1.jpg',
        'price': 6000,
      },
      {
        'name': 'dreem hush',
        'url': 'assets/images/arvi2.jpg',
        'price': 8000,
      },
      {
        'name': 'dreem yan',
        'url': 'assets/images/arvi3.jpg',
        'price': 4000,
      },
      {
        'name': 'dreem san',
        'url': 'assets/images/arvi4.jpg',
        'price': 6000,
      },
      {
        'name': 'dreem kal',
        'url': 'assets/images/arvi5.jpg',
        'price': 7000,
      },
      {
        'name': 'dreem jino',
        'url': 'assets/images/arvi6.jpg',
        'price': 8000,
      },
      {
        'name': 'dreem pino',
        'url': 'assets/images/arvi7.jpg',
        'price': 7500,
      },
      {
        'name': 'dreem latani',
        'url': 'assets/images/arvi8.jpg',
        'price': 9000,
      },
      {
        'name': 'nightking',
        'url': 'assets/images/homewallpepar.webp',
        'price': 15000,
      },
      {
        'name': 'dreemking',
        'url': 'assets/images/roomlistnew.webp',
        'price': 25000,
      },
      {
        'name': 'dreemrose',
        'url': 'assets/images/roomlistwallpaper.webp',
        'price': 28000,
      },
      {
        'name': 'Sher Queen',
        'url': 'assets/images/shherqwin.webp',
        'price': 120000,
      },
      {
        'name': 'Royal Queen',
        'url': 'assets/images/royalqwin.webp',
        'price': 130000,
      },
      {
        'name': 'Romantic Love',
        'url': 'assets/images/romanticlove.webp',
        'price': 110000,
      },
      {
        'name': 'Romantic',
        'url': 'assets/images/romantic.webp',
        'price': 85000,
      },
      {
        'name': 'King & Queen Wallpaper',
        'url': 'assets/images/kingweenwallpepar.webp',
        'price': 95000,
      },
      {
        'name': 'King Royal',
        'url': 'assets/images/kingroyal.webp',
        'price': 90000,
      },
      {
        'name': 'King & Queen Love',
        'url': 'assets/images/kingqwinlove.webp',
        'price': 100000,
      },
      {
        'name': 'King',
        'url': 'assets/images/king.webp',
        'price': 76000,
      },
      {
        'name': 'Couple Wallpaper',
        'url': 'assets/images/cuplewallpepar.webp',
        'price': 75000,
      },
      {
        'name': 'Blue Queen',
        'url': 'assets/images/bluqwen.webp',
        'price': 88000,
      },
    ];

    // রুমের বর্তমান কেনা থিম বা ডেটা চেক করার জন্য
    var roomDoc =
        await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    var roomData = roomDoc.data() ?? {};
    List purchasedWallpapers = roomData['purchasedWallpapers'] ?? [];
    String currentWallpaper = roomData['currentWallpaper'] ?? '';

    showDialog(
      context: context,
      builder: (dContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1B1A55),
                  Color(0xFF4A154B),
                ],
              ),
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.3), width: 1.2),
            ),
            padding: const EdgeInsets.all(20),
            height: 450,
            child: Column(
              children: [
                const Text(
                  "Room Themes & Wallpapers",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: wallpapers.length,
                    itemBuilder: (context, index) {
                      var item = wallpapers[index];
                      String themeName = item['name'] ??
                          'Theme ${index + 1}'; // থিমের নাম লোড করা
                      String wpUrl = item['url']; // এখানে অ্যাসেট পাথ কাজ করবে
                      int price = item['price'];
                      bool isBought = purchasedWallpapers.contains(wpUrl) ||
                          price == 0; // ফ্রি বা কেনা থাকলে

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                wpUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey,
                                  child: const Icon(Icons.image,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    themeName, // এখানে প্রতিটি থিমের নিজস্ব নাম শো করবে
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    isBought ? "Unlocked" : "Price: $price 💎",
                                    style: TextStyle(
                                        color: isBought
                                            ? Colors.greenAccent
                                            : Colors.cyanAccent,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // কেনা না থাকলে 'Buy' বাটন, কেনা থাকলে 'Pick' বাটন দেখাবে
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBought
                                    ? Colors.cyanAccent.withOpacity(0.2)
                                    : Colors.purpleAccent.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                if (isBought) {
                                  // পিক করলে মেইন রুমে ওয়ালপেপার সেট হয়ে যাবে
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomId)
                                      .update({
                                    'currentWallpaper': wpUrl,
                                  });
                                  onSetWallpaper(wpUrl);
                                  Navigator.pop(dContext);
                                  _showMessage(context,
                                      "Wallpaper applied successfully!");
                                } else {
                                  // ডায়মন্ড কেটে কেনার লজিক
                                  _handleThemePurchase(
                                      context, roomId, wpUrl, price,
                                      (updatedList) {
                                    setState(() {
                                      purchasedWallpapers = updatedList;
                                    });
                                  });
                                }
                              },
                              child: Text(
                                isBought ? "Pick" : "Buy",
                                style: TextStyle(
                                    color: isBought
                                        ? Colors.cyanAccent
                                        : Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// থিম কেনার ব্যাকএন্ড লজিক
  static void _handleThemePurchase(BuildContext context, String roomId,
      String wpUrl, int price, Function(List) onBoughtSuccess) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _showMessage(context, "Please login first!");
      return;
    }

    try {
      var userQuery = await _firestore
          .collection('users')
          .where(Filter.or(Filter('authUID', isEqualTo: user.uid),
              Filter('uID', isEqualTo: user.uid)))
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return;
      var userDoc = userQuery.docs.first;
      int myDiamonds = (userDoc.data()['diamonds'] ?? 0).toInt();

      if (myDiamonds >= price) {
        // ইউজারের ডায়মন্ড কমানো
        await _firestore
            .collection('users')
            .doc(userDoc.id)
            .update({'diamonds': myDiamonds - price});

        var roomRef = _firestore.collection('rooms').doc(roomId);
        var roomSnap = await roomRef.get();
        List purchased = roomSnap.data()?['purchasedWallpapers'] ?? [];
        purchased.add(wpUrl);

        // রুমে লিস্ট আপডেট করা
        await roomRef.update({'purchasedWallpapers': purchased});

        onBoughtSuccess(purchased);
        _showMessage(context, "Theme purchased successfully!");
      } else {
        _showMessage(context, "Insufficient Diamonds!");
      }
    } catch (e) {
      debugPrint("Theme Purchase Error: $e");
    }
  }

// --- সিট ক্রয় ডায়ালগ ---
  static void _showSeatPurchaseDialog(BuildContext context, String roomId,
      int layoutCount, Map<String, dynamic> roomData) {
    showDialog(
      context: context,
      builder: (dContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B2A),
                Color(0xFF1B1A55),
                Color(0xFF4A154B),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Unlock Seat Layout",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 15),
              Builder(
                builder: (BuildContext innerContext) {
                  return ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dContext);
                      await _processSeatPurchase(
                          innerContext, roomId, layoutCount, 100000);
                    },
                    child: const Text("1 Month (100k 💎)"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- সিট পারচেজ প্রসেসিং লজিক ---
  static Future<void> _processSeatPurchase(BuildContext context, String roomId,
      int layoutCount, int diamondsRequired) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage(context, "Please login first!");
      return;
    }

    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(Filter.or(Filter('authUID', isEqualTo: user.uid),
              Filter('uID', isEqualTo: user.uid)))
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return;
      var userDoc = userQuery.docs.first;
      int myDiamonds = (userDoc.data()['diamonds'] ?? 0).toInt();

      if (myDiamonds >= diamondsRequired) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .update({'diamonds': myDiamonds - diamondsRequired});

        DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .update({
          'seat_layout_${layoutCount}_package': {
            'expiry': Timestamp.fromDate(expiryDate),
            'boughtAt': FieldValue.serverTimestamp(),
          },
          'seatLayoutCount': layoutCount,
        });

        _showMessage(context, "Successfully unlocked for 30 days!");
      } else {
        _showMessage(context, "Insufficient Diamonds!");
      }
    } catch (e) {
      debugPrint("Seat Purchase Error: $e");
    }
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
                      onBuy(24, 16000);
                    },
                    child: const Text(
                      "24 Hours 16k💎",
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
                      onBuy(720, 110000);
                    },
                    child: const Text(
                      "30 Days 110k💎",
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
