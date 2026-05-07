import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/profile_page.dart'; 

class LiveViewersList extends StatelessWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 পরিবর্তন: distinct ব্যবহার করা হয়েছে যাতে সিটে কথা বলার সময় ভিউয়ার লিস্ট না কাঁপে
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('viewers')
          .snapshots(includeMetadataChanges: false)
          .distinct((prev, next) {
            // যদি ভিউয়ারদের সংখ্যা এবং প্রথম ইউজারের আইডি একই থাকে, তবে রিবিল্ড হবে না
            if (prev.docs.length != next.docs.length) return false;
            if (prev.docs.isEmpty && next.docs.isEmpty) return true;
            return prev.docs.first.id == next.docs.first.id;
          }), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        
        var viewers = snapshot.data?.docs ?? [];
        int count = viewers.length;

        return Row(
          children: [
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  key: const PageStorageKey('live_viewers_list'),
                  scrollDirection: Axis.horizontal,
                  itemCount: viewers.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  itemBuilder: (context, index) {
                    var viewerData = viewers[index].data() as Map<String, dynamic>;
                    String viewerId = viewerData['uID']?.toString() ?? viewers[index].id; 
                    String profileImage = viewerData['profilePic'] ?? viewerData['userImage'] ?? '';

                    return ViewerAvatar(
                      key: ValueKey(viewerId), // ইউনিক কি কথা বলার সময় ছবি স্থির রাখবে
                      viewerId: viewerId,
                      profileImage: profileImage,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ViewerAvatar extends StatelessWidget {
  final String viewerId;
  final String profileImage;

  const ViewerAvatar({
    super.key,
    required this.viewerId,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: viewerId),
            ),
          );
        },
        child: CircleAvatar(
          radius: 16,
          backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
          backgroundColor: Colors.grey[800],
          child: profileImage.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
        ),
      ),
    );
  }
}