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

  // ১. ইউজার সার্চ লজিক (সাথে এজেন্ট চেক)
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
        
        // 🔥 লজিক: যদি টার্গেট ইউজার একজন এজেন্ট হয়, তবে তাকে ব্লক করা হবে
        bool isTargetAgent = userData['isAgent'] ?? false;

        if (isTargetAgent) {
          setState(() => isLoading = false);
          _showSnackBar("আপনি অন্য কোন এজেন্টকে ডায়মন্ড পাঠাতে পারবেন না!");
        } else {
          setState(() {
            foundUser = userData;
            receiverFirestoreId = userDoc.docs.first.id;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar("ইউজার খুঁজে পাওয়া যায়নি!");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("সার্চ করতে সমস্যা হয়েছে");
    }
  }

  // ২. ডায়মন্ড ট্রান্সফার লজিক (ট্রানজেকশন)
  Future<void> confirmTransfer() async {
    if (foundUser == null || _amountController.text.isEmpty) return;

    int amount = int.parse(_amountController.text);
    if (amount <= 0) {
      _showSnackBar("সঠিক পরিমাণ লিখুন");
      return;
    }
    
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference senderRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
        DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverFirestoreId!);

        DocumentSnapshot senderSnap = await transaction.get(senderRef);
        int currentDiamonds = senderSnap['diamonds'] ?? 0;

        if (currentDiamonds < amount) {
          throw Exception("আপনার অ্যাকাউন্টে পর্যাপ্ত ডায়মন্ড নেই!");
        }

        // এজেন্টের ডায়মন্ড কমানো
        transaction.update(senderRef, {'diamonds': currentDiamonds - amount});

        // ইউজারের ডায়মন্ড বাড়ানো
        transaction.update(receiverRef, {'diamonds': FieldValue.increment(amount)});

        // ৩. PaglaChat Official থেকে ইউজারকে নোটিফিকেশন মেসেজ
        String chatId = "paglachat_official_$receiverFirestoreId"; 
        transaction.set(
          FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc(),
          {
            'senderId': 'paglachat_official',
            'receiverId': receiverFirestoreId,
            'text': "পাগলাচ্যাট অফিসিয়াল: আপনি সফলভাবে $amount ডায়মন্ড রিচার্জ পেয়েছেন।",
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          }
        );

        // ৪. ট্রানজেকশন হিস্ট্রি (রেকর্ড রাখা)
        transaction.set(
          FirebaseFirestore.instance.collection('diamond_history').doc(),
          {
            'senderId': currentUserId,
            'receiverId': receiverFirestoreId,
            'amount': amount,
            'type': 'agency_transfer',
            'date': DateTime.now().toString(),
            'timestamp': FieldValue.serverTimestamp(),
          }
        );
      });

      _showSnackBar("অভিনন্দন! ডায়মন্ড সফলভাবে পাঠানো হয়েছে।");
      
      setState(() {
        foundUser = null;
        _idController.clear();
        _amountController.clear();
        isLoading = false;
      });

    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(e.toString().replaceAll("Exception:", ""));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.pinkAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("এজেন্সি ডায়মন্ড ট্রান্সফার", style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // সার্চ বার ডিজাইন
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _idController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "ইউজার আইডি (ID) দিয়ে খুঁজুন...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (val) => searchUser(val.trim()),
              ),
            ),
            const SizedBox(height: 25),
            
            if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),

            // ইউজার পাওয়া গেলে এই কার্ডটি শো করবে
            if (foundUser != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2F),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                      backgroundImage: (foundUser!['imageURL'] != null && foundUser!['imageURL'] != "") 
                          ? NetworkImage(foundUser!['imageURL']) 
                          : null,
                      child: (foundUser!['imageURL'] == null || foundUser!['imageURL'] == "") 
                          ? const Icon(Icons.person, size: 50, color: Colors.white54) 
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(foundUser!['name'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("UID: ${foundUser!['userId']}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "ডায়মন্ডের পরিমাণ লিখুন",
                        hintStyle: TextStyle(color: Colors.white10),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: confirmTransfer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("নিশ্চিত করুন", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
