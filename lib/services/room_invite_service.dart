import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomInviteService {
  /// ১. ভিউয়ারকে সিটে বসার জন্য ইনভাইট পাঠানো (ফায়ারস্টোরে রিকোয়েস্ট সেভ করা)
  static Future<void> sendSeatInvite({
    required String roomId,
    required String targetUserId,
    required String targetUserName,
    required String inviterName,
  }) async {
    try {
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
    } catch (e) {
      debugPrint("Invite Error: $e");
    }
  }

  /// ২. ইনভাইট লিসেন করা এবং স্ক্রিনে পপআপ বা জয়েন বাটন দেখানো (ভিউয়ারের জন্য)
  static void listenForInvites({
    required BuildContext context,
    required String roomId,
    required String currentUserId,
    required Function(int seatIndex) onJoinSeat,
  }) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('invites')
        .doc(currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        String inviterName = data['inviterName'] ?? "Someone";

        // ইনভাইট পপআপ দেখানো
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF1E2A4A),
            title: const Text("Seat Invitation 🎙️",
                style: TextStyle(color: Colors.white)),
            content: Text(
              "$inviterName has invited you to take a seat on the stage!",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // ইনভাইট রিমুভ করে দেওয়া
                  FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .collection('invites')
                      .doc(currentUserId)
                      .delete();
                  Navigator.pop(dialogContext);
                },
                child: const Text("Reject", style: TextStyle(color: Colors.redAccent)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                onPressed: () {
                  // ইনভাইট ডিলিট করা
                  FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .collection('invites')
                      .doc(currentUserId)
                      .delete();
                  Navigator.pop(dialogContext);

                  // খালি সিটে জয়েন করার ফাংশন কল হবে
                  // (আপনার প্রজেক্টের সিট ইনডেক্স লজিক এখানে পাস করতে হবে)
                  onJoinSeat(0); // উদাহরণস্বরূপ প্রথম খালি সিট
                },
                child: const Text("Join", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      }
    });
  }
}