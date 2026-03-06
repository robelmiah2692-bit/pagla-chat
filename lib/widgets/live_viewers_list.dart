import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveViewersList extends StatelessWidget {
  final String roomId;
  const LiveViewersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // যে ইউজাররা এই রুমে আড্ডা দিচ্ছে তাদের লিস্ট আনা
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('viewers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var viewers = snapshot.data!.docs;

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              var viewer = viewers[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(viewer['userImage'] ?? ''),
                  backgroundColor: Colors.grey[800],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
