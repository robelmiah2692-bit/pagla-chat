import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgentTransferPage extends StatefulWidget {
  const AgentTransferPage({super.key});

  @override
  State<AgentTransferPage> createState() => _AgentTransferPageState();
}

class _AgentTransferPageState extends State<AgentTransferPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  Map<String, dynamic>? foundUser; 
  String? receiverFirestoreId; 
  bool isLoading = false;

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ১. ইউজার সার্চ লজিক (এজেন্ট চেকসহ)
  void searchUser(String userId) async {
    if (userId.isEmpty) return;
    
    setState(() {
      isLoading = true;
      foundUser = null;
    });
    
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: userId)
          .get();

      if (userDoc.docs.isNotEmpty) {
        var userData = userDoc.docs.first.data();
        
        // চেক: টার্গেট ইউজার কি একজন এজেন্ট?
        bool isTargetAgent = userData['isAgent'] ?? false;

        if (isTargetAgent) {
          setState(() => isLoading = false);
          _showSnackBar("আপনি অন্য কোন এজেন্টকে ডায়মন্ড পাঠাতে পারবেন না!", isError: true);
        } else {
          setState(() {
            foundUser = userData;
            receiverFirestoreId = userDoc.docs.first.id;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar("ইউজার খুঁজে পাওয়া যায়নি!", isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("সার্চ করতে সমস্যা হয়েছে");
    }
  }

  // ২. চূড়ান্ত ডায়মন্ড ট্রান্সফার লজিক (Transaction)
  Future<void> confirmTransfer() async {
    if (foundUser == null || _amountController.text.isEmpty) return;

    int amount = int.parse(_amountController.text);
    if (amount <= 0) {
      _showSnackBar("সঠিক পরিমাণ লিখুন", isError: true);
      return;
    }
    
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
        DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverFirestoreId!);

        DocumentSnapshot senderSnap = await transaction.get(senderRef);
        
        // 🔥 লজিক: এজেন্সি ওয়ালেট থেকে ডায়মন্ড চেক
        int currentAgencyWallet = senderSnap['agency_wallet'] ?? 0;

        if (currentAgencyWallet < amount) {
          throw Exception("আপনার এজেন্সি ওয়ালেটে পর্যাপ্ত ডায়মন্ড নেই!");
        }

        // ৩. এজেন্টের 'agency_wallet' থেকে ডায়মন্ড কমানো (পারসোনাল 'diamonds' নিরাপদ থাকবে)
        transaction.update(senderRef, {
          'agency_wallet': currentAgencyWallet - amount
        });

        // ৪. ইউজারের পারসোনাল ডায়মন্ড এবং XP বাড়ানো
        transaction.update(receiverRef, {
          'diamonds': FieldValue.increment(amount),
          'xp': FieldValue.increment(amount), // ইউজারের লেভেল বাড়বে
        });

        // ৫. PaglaChat Official থেকে ইউজারকে নোটিফিকেশন মেসেজ
        String chatId = "paglachat_official_$receiverFirestoreId"; 
        transaction.set(
          FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc(),
          {
            'senderId': 'paglachat_official',
            'receiverId': receiverFirestoreId,
            'text': "পাগলাচ্যাট অফিসিয়াল: আপনি সফলভাবে $amount ডায়মন্ড এবং $amount এক্সপি পেয়েছেন।",
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          }
        );

        // ৬. ট্রানজেকশন হিস্ট্রি (রেকর্ড রাখা)
        transaction.set(
          FirebaseFirestore.instance.collection('diamond_history').doc(),
          {
            'senderId': currentUserId,
            'receiverId': receiverFirestoreId,
            'amount': amount,
            'type': 'agency_transfer',
            'timestamp': FieldValue.serverTimestamp(),
          }
        );
      });

      _showSnackBar("অভিনন্দন! এজেন্সি ওয়ালেট থেকে ডায়মন্ড পাঠানো হয়েছে।");
      
      setState(() {
        foundUser = null;
        _idController.clear();
        _amountController.clear();
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(e.toString().replaceAll("Exception:", ""), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("এজেন্সি ডায়মন্ড ওয়ালেট", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // সার্চ বার
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "ইউজার আইডি দিয়ে খুঁজুন...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.pinkAccent),
                    onPressed: () => searchUser(_idController.text.trim()),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            
            if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),

            // ইউজার কার্ড
            if (foundUser != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2F),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.pinkAccent,
                      backgroundImage: (foundUser!['imageURL'] != null && foundUser!['imageURL'] != "") 
                          ? NetworkImage(foundUser!['imageURL']) 
                          : null,
                      child: (foundUser!['imageURL'] == null || foundUser!['imageURL'] == "") 
                          ? const Icon(Icons.person, size: 50, color: Colors.white) 
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(foundUser!['name'] ?? "ইউজার", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("ID: ${foundUser!['userId']}", style: const TextStyle(color: Colors.white54)),
                    const Divider(color: Colors.white10, height: 30),
                    
                    TextField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "ডায়মন্ড পরিমাণ",
                        hintStyle: TextStyle(color: Colors.white10),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: confirmTransfer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("ডায়মন্ড সেন্ড করুন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
