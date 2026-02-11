import 'package:flutter/material.dart';
// এখানে আপনার প্রোজেক্টের নাম 'pagla_app' ব্যবহার করে সরাসরি পাথ দেওয়া হয়েছে
import 'package:pagla_app/core/constants.dart';

class RoomActionMenu extends StatelessWidget {
  const RoomActionMenu({super.key});

  void _handleAction(BuildContext context, String action) {
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$action ফিচারটি চালু হচ্ছে..."),
        backgroundColor: AppConstants.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 30),
          
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMenuItem(context, Icons.music_note_rounded, "Music", Colors.blue),
              _buildMenuItem(context, Icons.play_circle_filled_rounded, "YouTube", Colors.red),
              _buildMenuItem(context, Icons.videogame_asset_rounded, "Games", Colors.orange),
              _buildMenuItem(context, Icons.bolt_rounded, "PK Battle", Colors.purple),
              _buildMenuItem(context, Icons.stars_rounded, "Privilege", Colors.amber),
              _buildMenuItem(context, Icons.card_giftcard_rounded, "Lucky Bag", Colors.teal),
              _buildMenuItem(context, Icons.settings_suggest_rounded, "Room Set", Colors.grey),
              _buildMenuItem(context, Icons.cleaning_services_rounded, "Clear", Colors.lightGreen),
            ],
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => _handleAction(context, label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
