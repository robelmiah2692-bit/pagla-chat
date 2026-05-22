import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 কারেন্ট ইউজার ভেরিফিকেশনের জন্য যুক্ত করা হলো
import 'package:pagla_chat/profile_page.dart';

// এই ক্লাসটি এখন একদম আলাদা, তাই এটি কাঁপবে না
class LiveViewersList extends StatefulWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  State<LiveViewersList> createState() => _LiveViewersListState();
}

class _LiveViewersListState extends State<LiveViewersList> {
  // স্ট্রীমটিকে একবার ইনিশিয়েট করছি যাতে বারবার নতুন কানেকশন না তৈরি হয়
  late Stream<QuerySnapshot> _viewerStream;

  @override
  void initState() {
    super.initState();
    _viewerStream = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('viewers')
        .snapshots(includeMetadataChanges: false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _viewerStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
           debugPrint("🚀 ভিউয়ার এরিয়া রেন্ডার হচ্ছে: ${snapshot.data!.docs.length} জন");
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();

        final docs = snapshot.data?.docs ?? [];
        
        return Row(
          children: [
            if (docs.isNotEmpty) _buildCount(docs.length),
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  cacheExtent: 1000, 
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // 🔍 [মাস্টার আইডি ফিল্টার]: ফিল্ডের অগ্রাধিকার সেট করা হলো যাতে ভুল আইডি পাস না হয়
                    // আপনার ডাটাবেজ অনুযায়ী ডকুমেন্ট আইডি (docs[index].id) হচ্ছে লম্বা AuthUID
                    final String actualAuthUID = docs[index].id;
                                                 
                    final img = data['profilePic'] ?? data['userImage'] ?? '';
                    final name = data['userName'] ?? data['name'] ?? 'Unknown';

                    return ViewerAvatar(
                      key: ValueKey("viewer_$actualAuthUID"), 
                      viewerId: actualAuthUID,
                      profileImage: img,
                      viewerName: name, // নাম প্রিন্ট ট্র্যাকিং এর জন্য পাস করা হলো
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
        color: Colors.black54, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 11)),
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
          
          // 🔥 [মাস্টার প্রিন্ট লগ]: এই প্রিন্টটি টার্মিনালে চেক করুন, জট একদম খুলে যাবে!
          debugPrint("=========================================================");
          debugPrint("🚨 [VIEWER CLICKED] ভিউয়ার লিস্টে ক্লিক করা হয়েছে!");
          debugPrint("👤 ক্লিক করা ভিউয়ারের নাম: ${widget.viewerName}");
          debugPrint("🆔 ক্লিক করা ভিউয়ারের লম্বা Auth ID: ${widget.viewerId}");
          debugPrint("🎯 Users কালেকশন থেকে প্রাপ্ত ৬-ডিজিটের uID (Target ID): $finalIdToPass");
          debugPrint("🔑 আমার নিজের লগইন আইডি (My Current ID): $myCurrentUid");
          debugPrint("📢 মেলানো হচ্ছে: $finalIdToPass == $myCurrentUid ? নিজের প্রোফাইল : অন্যের প্রোফাইল");
          debugPrint("📂 [ROUTING] ProfilePage-এ এই আইডিটি পাঠানো হচ্ছে -> $finalIdToPass");
          debugPrint("=========================================================");
          
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