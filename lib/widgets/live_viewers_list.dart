import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        // এই প্রিন্টটি যদি এখনো খুব দ্রুত আসে, তবে বুঝতে হবে ডাটাবেজে কথা বলার সময় ডাটা কাঁপছে
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
                  // 'physics' যোগ করা হয়েছে স্ক্রলিং স্মুথ করতে
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  cacheExtent: 1000, 
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uID = data['uID']?.toString() ?? docs[index].id;
                    final img = data['profilePic'] ?? data['userImage'] ?? '';

                    // ValueKey এবং RepaintBoundary কাঁপাকাঁপি বন্ধের প্রধান অস্ত্র
                    return ViewerAvatar(
                      key: ValueKey("viewer_$uID"), 
                      viewerId: uID,
                      profileImage: img,
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
  const ViewerAvatar({super.key, required this.viewerId, required this.profileImage});

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
        // 🔥 ফিক্স: এখানে থার্ড ব্র্যাকেট দিয়ে লগ প্রিন্ট দুটি বসানো হয়েছে
        onTap: () {
          debugPrint("🚨 [VIEWER CLICK LOG] ভিউয়ার লিস্টের ইউজারে ক্লিক করা হয়েছে!");
          debugPrint("🔎 [TARGET USER ID] ক্লিক করা ইউজারের ID: ${widget.viewerId}");
          debugPrint("📂 [ROUTING INFO] আমি এখন 'lib/profile_page.dart' ফাইলের ProfilePage-এ পাঠাচ্ছি।");
          
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: widget.viewerId),
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
                    gaplessPlayback: true, // ছবি পরিবর্তনের সময় ঝিলিক মারা বন্ধ করবে
                  ),
                ),
          ),
        ),
      ),
    );
  }
}