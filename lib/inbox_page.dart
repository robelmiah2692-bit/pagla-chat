import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  // ১. ডামি ফ্রেন্ড লিস্ট (এগুলো পরে ফায়ারবেস থেকে আসবে)
  final List<Map<String, dynamic>> friends = [
    {"name": "পাগলা বন্ধু ১", "id": "101", "isOnline": true, "currentRoom": "আড্ডা ঘর ১", "lastMsg": "কিরে কই তুই?"},
    {"name": "নানি জান", "id": "102", "isOnline": true, "currentRoom": "গল্পের আসর", "lastMsg": "কেমন আছো?"},
    {"name": "অচেনা কেউ", "id": "103", "isOnline": false, "currentRoom": "", "lastMsg": "হাই!"},
  ];

  // ২. আইডি দিয়ে বন্ধু খোঁজার ফাংশন
  void _showSearchDialog() {
    TextEditingController idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("আইডি দিয়ে খুঁজুন", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: idController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "আইডি নাম্বার লিখুন...", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাদ দিন")),
          ElevatedButton(
            onPressed: () {
              // এখানে আইডি দিয়ে প্রোফাইল খোঁজার লজিক
              Navigator.pop(context);
              _showMessage("ইউজার আইডি ${idController.text} খোঁজা হচ্ছে...");
            },
            child: const Text("সার্চ"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text("ইনবক্স", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search, color: Colors.pinkAccent, size: 30),
            onPressed: _showSearchDialog, // আইডি সার্চ বাটন
          ),
        ],
      ),
      body: Column(
        children: [
          // নতুন/পুরাতন মেসেজ ফিল্টার বাটন (ছোট করে)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              children: [
                _buildFilterChip("সব", true),
                const SizedBox(width: 10),
                _buildFilterChip("অনলাইন", false),
              ],
            ),
          ),
          
          // ফ্রেন্ডস ও মেসেজ লিস্ট
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                var friend = friends[index];
                return _buildChatTile(friend);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ৩. চ্যাট লিস্ট টাইল ডিজাইন
  Widget _buildChatTile(Map<String, dynamic> friend) {
    return ListTile(
      leading: Stack(
        children: [
          const CircleAvatar(backgroundColor: Colors.white10, radius: 25, child: Icon(Icons.person, color: Colors.pinkAccent)),
          if (friend["isOnline"])
            const Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 6, backgroundColor: Colors.green,)),
        ],
      ),
      title: Text(friend["name"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(friend["lastMsg"], style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (friend["isOnline"] && friend["currentRoom"].isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.live_tv, color: Colors.pinkAccent, size: 12),
                  const SizedBox(width: 5),
                  Text("লাইভ: ${friend['currentRoom']}", style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
      trailing: friend["isOnline"] 
        ? ElevatedButton(
            onPressed: () => _showMessage("${friend['currentRoom']} রুমে নিয়ে যাওয়া হচ্ছে..."),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(60, 30)),
            child: const Text("প্রবেশ", style: TextStyle(fontSize: 10)),
          )
        : const Text("অফলাইন", style: TextStyle(color: Colors.white10, fontSize: 10)),
      onTap: () {
        // চ্যাট বক্স ওপেন করার লজিক
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.pinkAccent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
