import 'package:flutter/material.dart';
import '../core/constants.dart';

class RoomActionMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // উপরে ছোট টান (ডিজাইন)
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          SizedBox(height: 25),
          
          // অপশন গ্রিড
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            children: [
              _actionItem(Icons.music_note_rounded, "Music", Colors.blueAccent),
              _actionItem(Icons.play_circle_filled_rounded, "YouTube", Colors.redAccent),
              _actionItem(Icons.videogame_asset_rounded, "Games", Colors.orangeAccent),
              _actionItem(Icons.bolt_rounded, "PK Battle", Colors.purpleAccent),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
