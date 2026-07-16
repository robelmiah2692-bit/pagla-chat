import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelpDeskPage extends StatefulWidget {
  const HelpDeskPage({super.key});

  @override
  State<HelpDeskPage> createState() => _HelpDeskPageState();
}

class _HelpDeskPageState extends State<HelpDeskPage> {
  // আপনার এজেন্টের আইডিগুলো
  final List<String> agentIds = ["978051", "680511", "294058", "500660","686008","571783","346306","219616","519857","765259","778741",]; 
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    messages.add({"role": "ai", "text": "Hello! I am Pagla AI. I can help you find an online support agent. Click the button below."});
  }

  Future<void> _findOnlineAgent() async {
    setState(() => _isLoading = true);
    
    String foundAgentId = "";
    
    for (String id in agentIds) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          
          // আপনার স্ক্রিনশট অনুযায়ী ফিল্ডের নাম 'isOnline' এবং এটি একটি boolean (true/false)
          bool isOnline = data['isOnline'] == true;
          
          if (isOnline) {
            foundAgentId = id;
            break;
          }
        }
      } catch (e) {
        debugPrint("Error checking agent $id: $e");
      }
    }

    setState(() {
      if (foundAgentId.isNotEmpty) {
        messages.add({
          "role": "ai", 
          "text": "Good news! I found an online agent. You can contact them by searching this ID in the chat list:", 
          "agentId": foundAgentId
        });
      } else {
        messages.add({
          "role": "ai", 
          "text": "Sorry, no support agents are currently online. Please try again later."
        });
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagla AI Support"), 
        backgroundColor: const Color(0xFF0F0C29)
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Column(
                  crossAxisAlignment: msg['role'] == 'ai' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg['role'] == 'ai' ? Colors.grey[200] : Colors.blueAccent, 
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(msg['text'], style: TextStyle(color: msg['role'] == 'ai' ? Colors.black : Colors.white)),
                    ),
                    if (msg.containsKey('agentId'))
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg['agentId']));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agent ID Copied!")));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("ID: ${msg['agentId']} ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Icon(Icons.copy, size: 16),
                            ],
                          ),
                        ),
                      )
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.all(15)),
                  onPressed: _findOnlineAgent,
                  child: const Text("Ask AI for Help", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            )
        ],
      ),
    );
  }
}