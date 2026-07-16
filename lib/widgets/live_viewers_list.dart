import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // ফায়ারবেস ডাটাবেস ইম্পোর্ট
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/profile_page.dart';

class LiveViewersList extends StatefulWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  State<LiveViewersList> createState() => _LiveViewersListState();
}

class _LiveViewersListState extends State<LiveViewersList> {
  // স্ট্রীম টাইপ পরিবর্তন করে DatabaseEvent দেওয়া হয়েছে
  late Stream<DatabaseEvent> _viewerStream;

  @override
  void initState() {
    super.initState();
    // RTDB পাথ সেট করা
    _viewerStream = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/viewers')
        .onValue;
  }

  @override
Widget build(BuildContext context) {
  return StreamBuilder<DatabaseEvent>(
    stream: _viewerStream,
    builder: (context, snapshot) {
      // ১. ডাটা লোডিং বা এরর হ্যান্ডলিং
      if (snapshot.hasError) return const SizedBox();
      if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
        return const SizedBox();
      }

      // ২. RTDB থেকে ডাটা সঠিকভাবে ম্যাপে কনভার্ট করা
      final dynamic rawValue = snapshot.data!.snapshot.value;
      final List<Map<String, dynamic>> viewersList = [];

      if (rawValue is Map) {
        rawValue.forEach((key, value) {
          if (value is Map) {
            viewersList.add({...Map<String, dynamic>.from(value), 'id': key});
          }
        });
      }

      // ৩. যদি কোনো ইউজার না থাকে
      if (viewersList.isEmpty) return const SizedBox();

      return Row(
        children: [
          _buildCount(viewersList.length),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: viewersList.length,
                itemBuilder: (context, index) {
                  final data = viewersList[index];
                  final String actualAuthUID = data['id'] ?? '';
                  final img = data['profilePic'] ?? '';
                  final name = data['name'] ?? 'Guest';

                  return ViewerAvatar(
                    key: ValueKey("viewer_$actualAuthUID"),
                    viewerId: actualAuthUID,
                    profileImage: img,
                    viewerName: name,
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
  Widget _buildCount(int count) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Text("$count",
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}



class ViewerAvatar extends StatefulWidget {
  final String viewerId;
  final String profileImage;
  final String viewerName; // ট্র্যাকিং ভ্যারিয়েবল
  const ViewerAvatar({
    super.key, 
    required this.viewerId, 
    required this.profileImage,
    required this.viewerName,
  });

  @override
  State<ViewerAvatar> createState() => _ViewerAvatarState();
}

class _ViewerAvatarState extends State<ViewerAvatar> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: GestureDetector(
        onTap: () async {
          String myCurrentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
          
          // 🔄 [ইউজার আইডি ট্র্যাকিং ফিক্স]: লম্বা AuthID দিয়ে users কালেকশন থেকে ৬-ডিজিটের uID বের করার লজিক
          String finalIdToPass = widget.viewerId;
          
          try {
            var userQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('authUID', isEqualTo: widget.viewerId) // আপনার রাস্তা: email, authUID, users, uID
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              // ৬-ডিজিটের ছোট uID ফিল্ডটি রিড করা হচ্ছে
              finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ?? userQuery.docs.first.id;
            }
          } catch (e) {
            debugPrint("❌ Users কালেকশন থেকে uID লোড করতে ব্যর্থ: $e");
          }
          
          
          if (!mounted) return;
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: finalIdToPass),
            ),
          );
        },
        
        child: RepaintBoundary( 
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white10,
            child: widget.profileImage.isEmpty 
              ? const Icon(Icons.person, size: 18, color: Colors.white30) 
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.profileImage,
                    fit: BoxFit.cover,
                    width: 32,
                    height: 32,
                    gaplessPlayback: true,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}