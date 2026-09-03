import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RoomInviteService {
  static Future<void> sendSeatInvite({
    required String roomId,
    required String targetUserId,
    String? targetAuthUid,
    required String targetUserName,
    required String inviterName,
  }) async {
    try {
      if (targetAuthUid == null || targetAuthUid.isEmpty) {
        if (targetUserId.isNotEmpty) {
          try {
            var userDoc = await FirebaseFirestore.instance.collection('users').doc(targetUserId).get();
            if (userDoc.exists) {
              targetAuthUid = userDoc.data()?['authUID'] ?? userDoc.data()?['uid'] ?? userDoc.id;
            }
          } catch (_) {}
        }
      }

      if (targetUserId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('invites')
            .doc(targetUserId)
            .set({
          'targetUserId': targetUserId,
          'inviterName': inviterName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (targetAuthUid != null && targetAuthUid.isNotEmpty && targetAuthUid != targetUserId) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('invites')
            .doc(targetAuthUid)
            .set({
          'targetUserId': targetAuthUid,
          'inviterName': inviterName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  static void listenForInvites({
    required BuildContext context,
    required String roomId,
    required String currentUserId,
    required String currentAuthUid,
    required Function(int seatIndex) onJoinSeat,
  }) {
    if (currentUserId.isNotEmpty) {
      _listenToDoc(context, roomId, currentUserId, onJoinSeat);
    }

    if (currentAuthUid.isNotEmpty && currentAuthUid != currentUserId) {
      _listenToDoc(context, roomId, currentAuthUid, onJoinSeat);
    }
  }

  static void _listenToDoc(
    BuildContext context,
    String roomId,
    String docId,
    Function(int seatIndex) onJoinSeat,
  ) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('invites')
        .doc(docId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        String inviterName = data['inviterName'] ?? "Host";

        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D021A), // Dark deep void
                    Color(0xFF2E0854), // Rich dark purple/indigo core
                    Color(0xFF060919), // Deep shadow blue
                  ],
                ),
                border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.deepOrangeAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Fire & Smoke Heart Glow effect overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CustomPaint(
                        painter: SmokeHeartGlowPainter(),
                      ),
                    ),
                  ),
                  
                  // Dialog Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Seat Invitation 🎙️",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "$inviterName has invited you to take a seat on the stage!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomId)
                                      .collection('invites')
                                      .doc(docId)
                                      .delete();
                                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                                },
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(roomId)
                                      .collection('invites')
                                      .doc(docId)
                                      .delete();
                                  
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  final dbRef = FirebaseDatabase.instance.ref('rooms/$roomId/seats');
                                  final event = await dbRef.once();
                                  
                                  int targetSeatIndex = -1;
                                  if (event.snapshot.value != null) {
                                    final value = event.snapshot.value;
                                    Map<dynamic, dynamic> seatsMap = (value is Map) ? value : (value is List ? value.asMap() : {});

                                    for (int i = 0; i < 12; i++) {
                                      var seat = seatsMap[i.toString()] ?? seatsMap[i];
                                      bool isOcc = seat != null ? (seat['isOccupied'] == true) : false;
                                      if (!isOcc) {
                                        targetSeatIndex = i;
                                        break;
                                      }
                                    }
                                  } else {
                                    targetSeatIndex = 0;
                                  }

                                  if (targetSeatIndex != -1) {
                                    onJoinSeat(targetSeatIndex);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("All seats are full!"), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: const Text(
                                      "Join",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }, onError: (_) {});
  }
}

// Custom Painter to mimic the exact vibrant neon flame and smoke heart gradient background vibe
class SmokeHeartGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Top-Left Warm Fire Glow (Orange/Red/Pink)
    paint.shader = RadialGradient(
      center: const Alignment(-0.6, -0.6),
      radius: 0.8,
      colors: [
        const Color(0xFFFF2A5F).withOpacity(0.35),
        const Color(0xFFFF7A00).withOpacity(0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bottom-Right Cool Smoke Glow (Blue/Cyan/Purple)
    paint.shader = RadialGradient(
      center: const Alignment(0.7, 0.7),
      radius: 0.9,
      colors: [
        const Color(0xFF4A00E0).withOpacity(0.4),
        const Color(0xFF8E2DE2).withOpacity(0.25),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Center subtle heart aura accent
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 0.5,
      colors: [
        const Color(0xFFFF3366).withOpacity(0.15),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}