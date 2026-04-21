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

  // ১. ইউজার সার্চ লজিক (Email, uID, authUID, uid - সব ফিল্ডে খুঁজবে)
  void searchUser(String input) async {
    if (input.isEmpty) return;

    setState(() {
      isLoading = true;
      foundUser = null;
      receiverFirestoreId = null;
    });

    try {
      QuerySnapshot queryRes;

      // ক. প্রথমে সরাসরি ডকুমেন্ট আইডি (uID) দিয়ে খোঁজা
      var directDoc = await FirebaseFirestore.instance.collection('users').doc(input).get();

      if (directDoc.exists) {
        _processFoundUser(directDoc.data() as Map<String, dynamic>, directDoc.id);
        return;
      }

      // খ. যদি না পায়, তবে email দিয়ে খোঁজা
      queryRes = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();

      // গ. যদি না পায়, তবে uID (String/Number) দিয়ে খোঁজা
      if (queryRes.docs.isEmpty) {
        queryRes = await FirebaseFirestore.instance
            .collection('users')
            .where('uID', isEqualTo: input)
            .limit(1)
            .get();
      }

      // ঘ. যদি না পায়, তবে authUID দিয়ে খোঁজা
      if (queryRes.docs.isEmpty) {
        queryRes = await FirebaseFirestore.instance
            .collection('users')
            .where('authUID', isEqualTo: input)
            .limit(1)
            .get();
      }

      // ঙ. যদি না পায়, তবে uid দিয়ে খোঁজা
      if (queryRes.docs.isEmpty) {
        queryRes = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (queryRes.docs.isNotEmpty) {
        _processFoundUser(queryRes.docs.first.data() as Map<String, dynamic>, queryRes.docs.first.id);
      } else {
        setState(() => isLoading = false);
        _showSnackBar("User not found! (Input: $input)", isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Error searching user: $e", isError: true);
    }
  }

  // ইউজার ডাটা প্রসেসিং লজিক (অন্য এজেন্টকে পাঠানো ব্লক করবে)
  void _processFoundUser(Map<String, dynamic> userData, String docId) {
    bool isTargetAgent = userData['isAgent'] ?? false;

    // টার্গেট ইউজার যদি এজেন্ট হয় এবং সে যদি আমি নিজে না হই (নিজেকে নিজে পাঠানো যাবে না বা অন্য এজেন্টকে না)
    if (isTargetAgent && docId != currentUserId) {
      setState(() => isLoading = false);
      _showSnackBar("You cannot send diamonds to another agent!", isError: true);
    } else {
      setState(() {
        foundUser = userData;
        receiverFirestoreId = docId;
        isLoading = false;
      });
    }
  }

  // ২. ডায়মন্ড ট্রান্সফার লজিক (agency_wallet এবং vip_xp ফিক্সড)
  Future<void> confirmTransfer() async {
    if (foundUser == null || _amountController.text.isEmpty || receiverFirestoreId == null) return;

    int amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showSnackBar("Enter a valid amount", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      int earnedXP = amount ~/ 250; // ২৫০ ডায়মন্ডে ১ এক্সপি

      // বর্তমান এজেন্টের ডাটা (authUID দিয়ে খোঁজা হচ্ছে আপনার প্রোফাইল)
      var agentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .limit(1)
          .get();

      if (agentQuery.docs.isEmpty) throw Exception("Agent record not found!");
      
      DocumentReference senderRef = agentQuery.docs.first.reference;
      DocumentReference receiverRef = FirebaseFirestore.instance.collection('users').doc(receiverFirestoreId!);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot senderSnap = await transaction.get(senderRef);
        
        if (!senderSnap.exists) throw Exception("Agent data not found!");

        Map<String, dynamic> senderData = senderSnap.data() as Map<String, dynamic>;
        
        // আপনার ডাটাবেস অনুযায়ী 'agency_wallet' ফিল্ড
        int currentAgencyWallet = (senderData['agency_wallet'] ?? 0).toInt();

        if (currentAgencyWallet < amount) {
          throw Exception("Insufficient balance in Agency Wallet!");
        }

        // এজেন্টের ওয়ালেট আপডেট
        transaction.update(senderRef, {
          'agency_wallet': currentAgencyWallet - amount
        });

        // ইউজারের ডায়মন্ড এবং vip_xp আপডেট
        transaction.update(receiverRef, {
          'diamonds': FieldValue.increment(amount),
          'vip_xp': FieldValue.increment(earnedXP),
        });

        // PaglaChat Official ইনবক্স নোটিফিকেশন
        String chatId = "paglachat_official_$receiverFirestoreId";
        DocumentReference msgRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        transaction.set(msgRef, {
          'senderId': 'paglachat_official',
          'receiverId': receiverFirestoreId,
          'text': "You have successfully received $amount Diamonds and $earnedXP XP bonus.",
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'system_msg'
        });

        // রিচার্জ হিস্ট্রি
        transaction.set(FirebaseFirestore.instance.collection('diamond_history').doc(), {
          'senderId': senderSnap.id, 
          'receiverId': receiverFirestoreId,
          'amount': amount,
          'earnedXP': earnedXP,
          'type': 'agency_transfer',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _showSnackBar("Success! Diamonds sent.");

      setState(() {
        foundUser = null;
        receiverFirestoreId = null;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ৩. ট্রানজেকশন হিস্ট্রি দেখার বটম শিট
  void _openHistorySheet() async {
    var agentQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('authUID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .limit(1)
        .get();
    
    String agentuID = agentQuery.docs.isNotEmpty ? agentQuery.docs.first.id : currentUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionHistoryWidget(agentId: agentuID),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("Agency Diamond Wallet", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            onPressed: _openHistorySheet,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // আপনার নিজের ব্যালেন্স দেখানোর উইজেট (Dynamic)
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
            ),
            const SizedBox(height: 25),

            if (isLoading) 
              const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),

            // ইউজার কার্ড (সার্চ রেজাল্ট)
            if (foundUser != null && !isLoading)
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
                      backgroundImage: (foundUser!['profilePic'] != null && foundUser!['profilePic'] != "")
                          ? NetworkImage(foundUser!['profilePic'])
                          : null,
                      child: (foundUser!['profilePic'] == null || foundUser!['profilePic'] == "")
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(foundUser!['name'] ?? "User",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("ID: ${foundUser!['uID'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54)),
                    const Divider(color: Colors.white10, height: 30),
                    
                    TextField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "Enter Amount",
                        hintStyle: TextStyle(color: Colors.white10),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
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
                        child: const Text("SEND DIAMONDS",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

class TransactionHistoryWidget extends StatelessWidget {
  final String agentId;
  const TransactionHistoryWidget({super.key, required this.agentId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF151525),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Transaction History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('diamond_history')
                  .where('senderId', isEqualTo: agentId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No transactions found", style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String formattedDate = "";
                    if(data['timestamp'] != null) {
                      formattedDate = DateFormat('dd MMM, hh:mm a').format((data['timestamp'] as Timestamp).toDate());
                    }

                    return Card(
                      color: const Color(0xFF1E1E2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.diamond, color: Colors.pinkAccent, size: 20)),
                        title: Text("Receiver ID: ${data['receiverId']}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: Text("${data['amount']} 💎", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
