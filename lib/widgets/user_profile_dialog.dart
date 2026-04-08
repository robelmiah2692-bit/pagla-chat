import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileDialog extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> userData;
  // 🔥 চোর ফিক্স: FirebaseAuth এর লম্বা আইডি (authUID)
  final String currentAuthId = FirebaseAuth.instance.currentUser?.uid ?? "";

  UserProfileDialog({super.key, required this.roomId, required this.userData});

  @override
  Widget build(BuildContext context) {
    // 🔥 চোর ফিক্স: টার্গেট ইউজারের ৬-ডিজিটের uID বা লম্বা আইডি নিশ্চিত করা
    final String targetUid = userData['uID'] ?? userData['uId'] ?? userData['userId'] ?? "";

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
              
              var roomData = snapshot.data!.data() as Map<String, dynamic>;
              
              // ⚔️ চোর জবাই: মালিকের আইডি শুধুমাত্র ownerId বা uID থেকে আসবে
              String ownerId = roomData['ownerId'] ?? roomData['uID'] ?? "";
              List admins = List.from(roomData['admins'] ?? []);

              // এখানে currentAuthId এর বদলে যদি আপনি অ্যাপে ৬-ডিজিটের ID ব্যবহার করেন তবে সেটা দিবেন
              bool isMeOwner = currentAuthId == ownerId; 
              bool isMeAdmin = admins.contains(currentAuthId);
              
              bool isTargetOwner = targetUid == ownerId;
              bool isTargetAdmin = admins.contains(targetUid);
              
              bool canControl = isMeOwner || isMeAdmin;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.blueAccent.withOpacity(0.05),
                      Colors.purpleAccent.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(targetUid, isTargetOwner, isTargetAdmin),
                    const SizedBox(height: 25),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _quickAction(Icons.alternate_email, "Mention", Colors.cyanAccent, () {
                          Navigator.pop(context, "@${userData['userName'] ?? userData['name']} ");
                        }),
                        _quickAction(Icons.person_add, "Follow", Colors.pinkAccent, () {}),
                        _quickAction(Icons.mail, "Message", Colors.greenAccent, () {}),
                      ],
                    ),

                    if (canControl) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(color: Colors.white12, thickness: 1),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: [
                          // মালিক শুধু অন্যদের এডমিন বানাতে পারবে
                          if (isMeOwner && !isTargetOwner)
                            _controlBtn(
                              isTargetAdmin ? "Remove Admin" : "Make Admin", 
                              isTargetAdmin ? Colors.orange : Colors.blue, 
                              Icons.security, 
                              () => _handleAdminStatus(targetUid, admins, isTargetAdmin)
                            ),

                          if (userData['isOnSeat'] != true)
                            _controlBtn("Invite Mic", Colors.green, Icons.mic, () {}),

                          if (userData['isOnSeat'] == true) ...[
                            _controlBtn("Leave Mic", Colors.deepOrange, Icons.logout, () {}),
                            _controlBtn("Mute", Colors.blueGrey, Icons.mic_off, () {}),
                          ],

                          // ওনার যে কাউকে কিক দিতে পারবে, এডমিন শুধু মেম্বারদের কিক দিতে পারবে
                          if (!isTargetOwner && (isMeOwner || (isMeAdmin && !isTargetAdmin)))
                            _controlBtn("Kick User", Colors.redAccent, Icons.gavel, () => _kickLogic(context, targetUid)),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleAdminStatus(String uid, List currentAdmins, bool alreadyAdmin) async {
    // ⚔️ চোর জবাই: একই ফিল্ডে আপডেট হবে
    if (alreadyAdmin) {
      currentAdmins.remove(uid);
    } else {
      currentAdmins.add(uid);
    }
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'admins': currentAdmins,
      // 'adminId' বা অন্য কিছু আলাদা করে রাখার দরকার নেই
    });
  }

  void _kickLogic(BuildContext context, String uid) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'followers': FieldValue.arrayRemove([uid]),
      'kickedUsers': FieldValue.arrayUnion([uid])
    });
    if (context.mounted) Navigator.pop(context);
  }

  Widget _buildHeader(String uid, bool isOwner, bool isAdmin) {
    String photo = userData['userImage'] ?? userData['photoUrl'] ?? userData['profilePic'] ?? "";
    String name = userData['userName'] ?? userData['name'] ?? "User";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.cyanAccent, Colors.purpleAccent]),
          ),
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.black54,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white24) : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        if (isOwner) 
          _badge("👑 Room Owner", Colors.amber)
        else if (isAdmin)
          _badge("🛡️ Administrator", Colors.blueAccent),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _controlBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
