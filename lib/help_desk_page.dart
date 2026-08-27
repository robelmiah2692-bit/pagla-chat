import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_service.dart'; // আপনার প্রজেক্ট অনুযায়ী ইমপোর্ট পাথ ঠিক করে নেবেন
import 'package:pagla_chat/profile_page.dart'; // আপনার প্রজেক্ট অনুযায়ী প্রোফাইল পেজের সঠিক পাথ দিন

class HelpDeskPage extends StatefulWidget {
  const HelpDeskPage({super.key});

  @override
  State<HelpDeskPage> createState() => _HelpDeskPageState();
}

class _HelpDeskPageState extends State<HelpDeskPage> {
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    messages.add({
      "role": "ai", 
      "text": "Hello! I am Pagla AI. I can help you find an online support agent. Click the button below."
    });
  }

  Future<void> _findOnlineAgent() async {
    setState(() => _isLoading = true);
    
    Map<String, dynamic>? foundAgentData;
    
    try {
      // ডাটাবেজ থেকে এজেন্ট আইডিগুলোর লিস্ট নিয়ে আসা
      List<String> agentIds = await SupportService.getAgentIds();

      for (String id in agentIds) {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          bool isOnline = data['isOnline'] == true;
          
          if (isOnline) {
            foundAgentData = {
              "id": id,
              "name": data['name'] ?? data['userName'] ?? "Support Agent",
              "image": data['image'] ?? data['profilePic'] ?? "",
            };
            break;
          }
        }
      }
    } catch (e) {
      // Handle error if needed
    }

    setState(() {
      if (foundAgentData != null) {
        messages.add({
          "role": "ai", 
          "text": "Good news! I found an online agent for you:", 
          "agent": foundAgentData
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
        title: const Text("Pagla AI Support", style: TextStyle(color: Colors.cyanAccent)), 
        backgroundColor: const Color(0xFF190033),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // সেটিংস উইন্ডোর মতো প্রিমিয়াম ব্লু ও পার্পল গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue
              Color(0xFF0083B0), // Mid Blue tone
              Color(0xFF4A00E0), // Deep Purple gradient match
              Color(0xFF190033), // Rich dark purple-blue base
            ],
          ),
        ),
        child: Stack(
          children: [
            // ব্যাকগ্রাউন্ডে তারার ঝিকিমিকি ইফেক্ট
            ...List.generate(
              15,
              (index) => Positioned(
                top: (index * 50.0) % 600,
                left: (index * 80.0) % 380,
                child: Icon(
                  Icons.star,
                  size: index % 3 == 0 ? 12 : 6,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            
            Column(
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
                              color: msg['role'] == 'ai' 
                                  ? Colors.white.withOpacity(0.12) 
                                  : Colors.blueAccent.withOpacity(0.8), 
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              msg['text'], 
                              style: TextStyle(
                                color: msg['role'] == 'ai' ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (msg.containsKey('agent'))
                            GestureDetector(
                              onTap: () {
                                // এজেন্টের কার্ডে ক্লিক করলেই সরাসরি তার প্রোফাইল পেজে চলে যাবে
                                String agentId = msg['agent']['id'];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(userId: agentId),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent[700]?.withOpacity(0.85), 
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: msg['agent']['image'] != "" 
                                          ? NetworkImage(msg['agent']['image']) 
                                          : null,
                                      child: msg['agent']['image'] == "" ? const Icon(Icons.person) : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['agent']['name'], 
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              "ID: ${msg['agent']['id']} ", 
                                              style: const TextStyle(color: Colors.white70, fontSize: 14)
                                            ),
                                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
                                          ],
                                        ),
                                      ],
                                    ),
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
                  const Padding(
                    padding: EdgeInsets.all(8.0), 
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  ),
                if (!_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.cyanAccent),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _findOnlineAgent,
                        child: const Text("Ask AI for Help", style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}