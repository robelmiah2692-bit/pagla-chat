import 'package:flutter/material.dart';

class RoomLobbyMenuSheet extends StatelessWidget {
  final VoidCallback onMusicTap;
  final VoidCallback onGiftToolsTap;
  final VoidCallback onGamesTap;

  const RoomLobbyMenuSheet({
    Key? key,
    required this.onMusicTap,
    required this.onGiftToolsTap,
    required this.onGamesTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A103C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: Colors.amberAccent, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "👑 Room Lobby Menu",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.music_note,
                label: "Music",
                color: const Color(0xFF75E1F4),
                onTap: () {
                  Navigator.pop(context);
                  onMusicTap();
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.star,
                label: "Gift & PK",
                color: Colors.purpleAccent,
                onTap: () {
                  Navigator.pop(context);
                  onGiftToolsTap();
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.videogame_asset,
                label: "Games",
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  onGamesTap();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}