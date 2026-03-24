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

  // ১. ইউজার সার্চ লজিক (uID ফিল্ড ব্যবহার করা হয়েছে)
  void searchUser(String inputId) async {
    if (inputId.isEmpty) return;

    setState(() {
      isLoading = true;
      foundUser = null;
      receiverFirestoreId = null;
    });

    try {
      // ডাটাবেসে ফিল্ডের নাম 'uID', তাই এখানে 'uID' দিয়ে সার্চ করা হচ্ছে
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: inputId)
          .get();

      // যদি String হিসেবে না পায়, তবে নাম্বার (int) হিসেবেও একবার চেষ্টা করবে
      if (userDoc.docs.isEmpty && int.tryParse(inputId) != null) {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('uID', isEqualTo: int.parse(inputId))
            .get();
      }

      if (userDoc.docs.isNotEmpty) {
        var userData = userDoc.docs.first.data();
        receiverFirestoreId = userDoc.docs.first.id;

        // চেক: টার্গেট ইউজার কি অন্য কোন এজেন্ট? 
        bool isTargetAgent = userData['isAgent'] ?? false;

        // আপনি নিজে নিজের আইডিতে ডায়মন্ড পাঠাতে পারবেন (টেস্টিং এর জন্য)
        if (isTargetAgent && receiverFirestoreId != currentUserId) {
          setState(() => isLoading = false);
          _showSnackBar("আপনি অন্য কোন এজেন্টকে ডায়মন্ড পাঠাতে পারবেন না!", isError: true);
        } else {
          setState(() {
            foundUser = userData;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar("ইউজার খুঁজে পাওয়া যায়নি! (ID: $inputId)", isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("সার্চ করতে সমস্যা হয়েছে");
    }
  }

  // ২. ডায়মন্ড ট্রান্সফার লজিক (Transaction)
  Future<void> confirmTransfer() async {
    if (foundUser == null || _amountController.text.isEmpty || receiverFirestoreId == null) return;

    int amount = int.tryParse(_amountController.text) ?? 0;
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
        
        if (!senderSnap.exists) throw Exception("এজেন্ট ডাটা পাওয়া যায়নি!");

        Map<String, dynamic> senderData = senderSnap.data() as Map<String, dynamic>;
        
        // আপনার ডাটাবেসে ফিল্ডের নাম 'agency_wallet' নাকি 'agencyDiamonds' তা চেক করবেন
        // আমি এখানে agency_wallet ই রেখেছি আপনার আগের কোড অনুযায়ী
        int currentAgencyWallet = (senderData['agency_wallet'] ?? 0).toInt();

        if (currentAgencyWallet < amount) {
          throw Exception("আপনার এজেন্সি ওয়ালেটে পর্যাপ্ত ডায়মন্ড নেই!");
        }

        // ৩. এজেন্টের 'agency_wallet' থেকে কমানো
        transaction.update(senderRef, {
          'agency_wallet': currentAgencyWallet - amount
        });

        // ৪. ইউজারের পারসোনাল ডায়মন্ড এবং XP বাড়ানো
        transaction.update(receiverRef, {
          'diamonds': FieldValue.increment(amount),
          'xp': FieldValue.increment(amount),
        });

        // ৫. সিস্টেম নোটিফিকেশন মেসেজ
        String chatId = "paglachat_official_$receiverFirestoreId";
        DocumentReference msgRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        transaction.set(msgRef, {
          'senderId': 'paglachat_official',
          'receiverId': receiverFirestoreId,
          'text': "আপনি সফলভাবে $amount ডায়মন্ড এবং $amount এক্সপি বোনাস পেয়েছেন।",
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'system_msg'
        });

        // ৬. ট্রানজেকশন হিস্ট্রি সেভ
        transaction.set(FirebaseFirestore.instance.collection('diamond_history').doc(), {
          'senderId': currentUserId,
          'receiverId': receiverFirestoreId,
          'amount': amount,
          'type': 'agency_transfer',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _showSnackBar("অভিনন্দন! ডায়মন্ড পাঠানো হয়েছে।");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("এজেন্সি ডায়মন্ড ওয়ালেট", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  hintText: "ইউজার আইডি (uID) দিয়ে খুঁজুন...",
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
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
              ),

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
                      backgroundImage: (foundUser!['imageURL'] != null && foundUser!['imageURL'] != "")
                          ? NetworkImage(foundUser!['imageURL'])
                          : null,
                      child: (foundUser!['imageURL'] == null || foundUser!['imageURL'] == "")
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(foundUser!['name'] ?? "ইউজার",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    // এখানেও 'uID' দেখানো হচ্ছে
                    Text("ID: ${foundUser!['uID'] ?? 'N/A'}", style: const TextStyle(color: Colors.white54)),
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
                        child: const Text("ডায়মন্ড সেন্ড করুন",
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
