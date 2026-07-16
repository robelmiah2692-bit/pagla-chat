import 'package:flutter/material.dart';

class LudoLobbyPopup extends StatelessWidget {
  final List<Map<String, dynamic>> joinedUsers;
  final bool isAdmin;
  final VoidCallback onJoin;
  final VoidCallback onStart;
  final VoidCallback onClose; // নতুন: পপ-আপ বন্ধ করার জন্য
  final Function(int) onUpdateBet; // নতুন: ডাইমন্ড কন্ট্রোলের জন্য
  final int betAmount;

  const LudoLobbyPopup({
    required this.joinedUsers,
    required this.isAdmin,
    required this.onJoin,
    required this.onStart,
    required this.onClose,
    required this.onUpdateBet,
    required this.betAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ক্লোজ বাটন এবং টাইটেল
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 40), // ব্যালেন্স ঠিক রাখার জন্য
              Text("Ludo Lobby", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: onClose),
            ],
          ),
          
          SizedBox(height: 10),
          
          // জয়েন ইউজার লিস্ট
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 5),
                child: joinedUsers.length > index
                    ? Column(
                        children: [
                          CircleAvatar(backgroundImage: NetworkImage(joinedUsers[index]['avatar'] ?? '')),
                          Text(joinedUsers[index]['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      )
                    : Icon(Icons.person_add, color: Colors.white.withOpacity(0.5)),
              );
            }),
          ),
          
          SizedBox(height: 15),
          
          // মালিকের ডাইমন্ড কন্ট্রোল
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAdmin)
                IconButton(icon: Icon(Icons.remove, color: Colors.white), onPressed: () => onUpdateBet(betAmount - 1)),
              
              Text("Entry Fee: $betAmount 💎", style: TextStyle(color: Colors.white, fontSize: 16)),
              
              if (isAdmin)
                IconButton(icon: Icon(Icons.add, color: Colors.white), onPressed: () => onUpdateBet(betAmount + 1)),
            ],
          ),
          
          SizedBox(height: 10),
          
          // বাটন সেকশন
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: onJoin, child: Text("Join")),
              SizedBox(width: 10),
              if (isAdmin && joinedUsers.length >= 2)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: onStart,
                  child: Text("Start Game"),
                ),
            ],
          )
        ],
      ),
    );
  }
}