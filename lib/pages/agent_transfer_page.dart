import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  // ইউজার ডাটা সার্চ লজিক ঠিক করা হয়েছে
  void searchUser(String input) async {
    if (input.isEmpty) return;

    setState(() {
      isLoading = true;
      foundUser = null;
      receiverFirestoreId = null;
    });

    try {
      // ১. সরাসরি ডকুমেন্ট আইডি (Firestore Doc ID) দিয়ে চেক
      var directDoc = await FirebaseFirestore.instance.collection('users').doc(input).get();
      if (directDoc.exists) {
        _processFoundUser(directDoc.data() as Map<String, dynamic>, directDoc.id);
        return;
      }

      // ২. অন্যান্য ফিল্ড (uID, email, authUID) দিয়ে চেক
      List<String> fields = ['uID', 'email', 'authUID', 'uid'];
      for (var field in fields) {
        var queryRes = await FirebaseFirestore.instance
            .collection('users')
            .where(field, isEqualTo: input)
            .limit(1)
            .get();
        
        if (queryRes.docs.isNotEmpty) {
          _processFoundUser(queryRes.docs.first.data() as Map<String, dynamic>, queryRes.docs.first.id);
          return;
        }
      }

      if (mounted) setState(() => isLoading = false);
      _showSnackBar("User not found!", isError: true);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showSnackBar("Error searching user: $e", isError: true);
    }
  }

  void _processFoundUser(Map<String, dynamic> userData, String docId) {
    bool isTargetAgent = userData['isAgent'] ?? false;
    String myAuthUID = FirebaseAuth.instance.currentUser?.uid ?? "";
    bool isMe = (userData['authUID'] == myAuthUID); 

    if (isTargetAgent && !isMe) {
      if (mounted) setState(() => isLoading = false);
      _showSnackBar("You cannot send diamonds to another agent!", isError: true);
    } else {
      if (mounted) {
        setState(() {
          foundUser = userData;
          receiverFirestoreId = docId;
          isLoading = false;
        });
      }
    }
  }

 Future<void> confirmTransfer() async {
  if (foundUser == null || _amountController.text.isEmpty || receiverFirestoreId == null) return;

  int amount = int.tryParse(_amountController.text) ?? 0;
  if (amount <= 0) {
    _showSnackBar("Enter a valid amount", isError: true);
    return;
  }

  if (mounted) setState(() => isLoading = true);

  try {
    int earnedXP = amount ~/ 250; 

    // ১. এজেন্টকে খুঁজে বের করা (সব আইডি লজিক দিয়ে)
    var agentQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(1)
        .get();

    if (agentQuery.docs.isEmpty) throw Exception("Agent record not found!");
    
    DocumentReference senderRef = agentQuery.docs.first.reference;
    String agentDocId = agentQuery.docs.first.id; // এজেন্টের আসল ডকুমেন্ট আইডি
    DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverFirestoreId!);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot senderSnap = await transaction.get(senderRef);
      if (!senderSnap.exists) throw Exception("Agent data not found!");

      int currentAgencyWallet = (senderSnap.get('agency_wallet') ?? 0).toInt();
      if (currentAgencyWallet < amount) throw Exception("Insufficient balance!");

      // ওয়ালেট আপডেট
      transaction.update(senderRef, {'agency_wallet': currentAgencyWallet - amount});
      transaction.update(receiverRef, {
        'diamonds': FieldValue.increment(amount),
        'vip_xp': FieldValue.increment(earnedXP),
      });

     // --- ২. ইউজারের ইনবক্সে অফিশিয়াল মেসেজ পাঠানো ---
      // আপনার চ্যাট সিস্টেমে chatId যেভাবে তৈরি হয় সেভাবে মেলাতে হবে
      String chatId = "paglachat_official_$receiverFirestoreId"; 
      
      DocumentReference chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      DocumentReference msgRef = chatDocRef.collection('messages').doc();

      // মেসেজ বডি
      Map<String, dynamic> officialMsg = {
        'senderId': 'paglachat_official',
        'receiverId': receiverFirestoreId,
        'text': "🎉 You've received $amount Diamonds and $earnedXP XP bonus from Official Agency.",
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'system_msg'
      };

      // মেসেজ সেট করা
      transaction.set(msgRef, officialMsg);

      // চ্যাট লিস্টে মেসেজটি দেখানোর জন্য মেইন চ্যাট ডকুমেন্ট আপডেট করা
      transaction.set(chatDocRef, {
        'lastMessage': "🎉 Received $amount Diamonds",
        'lastTimestamp': FieldValue.serverTimestamp(),
        'users': ['paglachat_official', receiverFirestoreId],
        'unReadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // ৩. ডায়মন্ড হিস্ট্রি সেভ করা (এজেন্টের আইডি দিয়ে যাতে সে দেখতে পায়)
      transaction.set(FirebaseFirestore.instance.collection('diamond_history').doc(), {
        'senderId': agentDocId, // এখানে ফিক্সড আইডি ব্যবহার করছি
        'receiverId': receiverFirestoreId,
        'receiverName': foundUser!['name'] ?? "User", // পরে দেখার সুবিধার জন্য নামও রাখলাম
        'amount': amount,
        'earnedXP': earnedXP,
        'type': 'agency_transfer',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // ৪. ইউজারের রিচার্জ হিস্টোরি (ইউজার তার রিচার্জ লিস্টে দেখতে পাবে)
      DocumentReference rechargeRef = receiverRef.collection('recharge_history').doc();
      transaction.set(rechargeRef, {
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'Agency Transfer',
        'status': 'Success'
      });
    });

    _showSnackBar("Success! Diamonds sent & User Notified.");
    if (mounted) {
      setState(() {
        foundUser = null;
        receiverFirestoreId = null;
        _idController.clear();
        _amountController.clear();
        isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => isLoading = false);
    _showSnackBar(e.toString().replaceAll("Exception:", ""), isError: true);
  }
}

  void _openHistorySheet() async {
  // নিশ্চিত করা হচ্ছে সঠিক এজেন্টের ডকুমেন্ট আইডি নেওয়া হচ্ছে
  var agentQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('authUID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .limit(1)
      .get();
  
  if (agentQuery.docs.isNotEmpty) {
    String agentDocId = agentQuery.docs.first.id;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionHistoryWidget(agentId: agentDocId),
    );
  } else {
    _showSnackBar("Agent ID not found for history", isError: true);
  }
}
void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating, // একটু স্টাইলিশ দেখানোর জন্য
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("Agency Diamond Wallet", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded, size: 28), onPressed: _openHistorySheet),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('authUID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
                var myData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Agency Wallet:", style: TextStyle(color: Colors.white70)),
                      Text("💎 ${myData['agency_wallet'] ?? 0}", 
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }
            ),
            _buildSearchInput(),
            if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
            if (foundUser != null && !isLoading) _buildUserCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: _idController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search by ID, Email, or uID...",
          hintStyle: const TextStyle(color: Colors.white24),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Colors.pinkAccent),
            onPressed: () => searchUser(_idController.text.trim()),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: (foundUser!['profilePic'] != null && foundUser!['profilePic'] != "") 
                ? NetworkImage(foundUser!['profilePic']) : null,
            child: (foundUser!['profilePic'] == null || foundUser!['profilePic'] == "") 
                ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 15),
          Text(foundUser!['name'] ?? "User", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: _amountController,
            style: const TextStyle(color: Colors.white, fontSize: 22),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: "Enter Amount", hintStyle: TextStyle(color: Colors.white10)),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: confirmTransfer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text("SEND DIAMONDS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionHistoryWidget extends StatelessWidget {
  final String agentId;
  const TransactionHistoryWidget({super.key, required this.agentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF151525),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text("Transaction History", 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('diamond_history')
                  .where('senderId', isEqualTo: agentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // ১. যদি কোনো এরর আসে (যেমন: ইনডেক্স সমস্যা)
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text("Error: ${snapshot.error}", 
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center),
                    ),
                  );
                }

                // ২. ডাটা লোড হওয়ার সময়
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                // ৩. যদি ডাটা খালি থাকে
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No history found", 
                    style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    
                    // টাইমস্ট্যাম্প সেফলি হ্যান্ডেল করা
                    String date = "Unknown Date";
                    if (data['timestamp'] != null) {
                      date = DateFormat('dd MMM, hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                    }

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.diamond, color: Colors.pinkAccent),
                      ),
                      title: Text("Receiver: ${data['receiverName'] ?? data['receiverId']}", 
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${data['amount']} 💎", 
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text("Success", style: TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}