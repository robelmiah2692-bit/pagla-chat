import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pagla_chat/diamond_grid_item.dart';
import 'package:pagla_chat/pages/agent_transfer_page.dart';

class DiamondStoreView extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isAgent;

  const DiamondStoreView(
      {Key? key, required this.userData, required this.isAgent})
      : super(key: key);

  @override
  State<DiamondStoreView> createState() => _DiamondStoreViewState();
}

class _DiamondStoreViewState extends State<DiamondStoreView> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ডায়মন্ড প্যাকের ম্যাপ
  final Map<String, Map<String, dynamic>> _diamondPacks = {
    'gem_pack_6k': {'amount': 6000, 'price': '\$0.99', 'display': '6k 💎'},
    'gem_pack_12k': {'amount': 12000, 'price': '\$1.49', 'display': '12k 💎'},
    'gem_pack_30k': {'amount': 30000, 'price': '\$3.49', 'display': '30k 💎'},
    'gem_pack_60k': {'amount': 60000, 'price': '\$6.49', 'display': '60k 💎'},
    'gem_pack_120k': {
      'amount': 120000,
      'price': '\$11.99',
      'display': '120k 💎'
    },
    'gem_pack_240k': {
      'amount': 240000,
      'price': '\$22.99',
      'display': '240k 💎'
    },
    'gem_pack_500k': {
      'amount': 500000,
      'price': '\$44.99',
      'display': '500k 💎'
    },
    'gem_pack_1m': {'amount': 1000000, 'price': '\$84.99', 'display': '1M 💎'},
    'gem_pack_2m': {'amount': 2000000, 'price': '\$169.99', 'display': '2M 💎'},
    'gem_pack_4m': {'amount': 4000000, 'price': '\$300', 'display': '4M 💎'},
    'gem_pack_8m': {'amount': 8000000, 'price': '\$550', 'display': '8M 💎'},
  };

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    }, onDone: () => _subscription?.cancel(), onError: (error) {
      debugPrint("Purchase Stream Error: $error");
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // পেমেন্ট হ্যান্ডেলার ও সিকিউরিটি ভেরিফিকেশন সিস্টেম
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        
        int? diamondsToAdd = _diamondPacks[purchase.productID]?['amount'];
        if (diamondsToAdd != null) {
          // ১. ডুপ্লিকেট বা ফেক ট্রানজেকশন চেক (Anti-Hack)
          bool isUnique = await _verifyAndPreventDuplicatePurchase(purchase);

          if (isUnique) {
            // ২. সার্ভার-সাইড ভেরিফিকেশন কল করা হচ্ছে
            bool isValidServer = await _verifyWithServer(purchase, diamondsToAdd);

            if (isValidServer) {
              // ৩. ফায়ারবেসে সিকিউরড উপায়ে ডায়মন্ড প্লাস করা হচ্ছে
              String finalTxnId = purchase.purchaseID ?? 
                  (purchase.verificationData.serverVerificationData.length > 20 
                      ? purchase.verificationData.serverVerificationData.substring(0, 20) 
                      : purchase.verificationData.serverVerificationData);
              await _updateUserDiamonds(diamondsToAdd, finalTxnId);
            } else {
              debugPrint("Server verification failed for this purchase token.");
            }
          }
        }

        // ৪. অ্যান্ড্রয়েডের জন্য পারচেজটি সেফলি কনজিউম ও কমপ্লিট করা (ডুপ্লিকেট কনজাম্পশন এড়ানোর জন্য ট্রাই-ক্যাচ সহ)
        if (purchase.pendingCompletePurchase) {
          final InAppPurchaseAndroidPlatformAddition androidAddition =
              _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              
          try {
            // যদি অলরেডি কনজিউম হয়ে থাকে তবে যেন ক্র্যাশ বা কোড ৮ না দেয়
            await androidAddition.consumePurchase(purchase);
          } catch (e) {
            debugPrint("Notice: Purchase already consumed or handled: $e");
          }

          try {
            await _iap.completePurchase(purchase);
          } catch (e) {
            debugPrint("Notice: Complete purchase skipped or already done: $e");
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint("Purchase Error: ${purchase.error?.message}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Purchase Failed: ${purchase.error?.message ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ডুপ্লিকেট পেমেন্ট বা হ্যাকড রসিদ চেক করার ফাংশন (Anti-Hack)
  Future<bool> _verifyAndPreventDuplicatePurchase(PurchaseDetails purchase) async {
    String? transactionId = purchase.purchaseID;
    if (transactionId == null || transactionId.isEmpty) {
      // অ্যান্ড্রয়েডের জন্য purchaseID না থাকলে serverVerificationData ব্যবহার করা হবে
      if (purchase.verificationData.serverVerificationData.isNotEmpty) {
        transactionId = purchase.verificationData.serverVerificationData;
      } else {
        return false; // কোনো আইডিই না থাকলে ভ্যালিড ধরব না
      }
    }

    try {
      final firestore = FirebaseFirestore.instance;
      
      // ডাটাবেজে চেক করা হচ্ছে এই ট্রানজেকশন আইডি ইতিপূর্বে ব্যবহার করা হয়েছে কি না
      QuerySnapshot existingTxn = await firestore
          .collection('completed_transactions')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (existingTxn.docs.isNotEmpty) {
        debugPrint("WARNING: Duplicate or fake transaction attempt detected: $transactionId");
        return false;
      }

      // নতুন ট্রানজেকশন হলে তা সিকিউরড কালেকশনে সেভ করে রাখা যাতে পুনরায় ব্যবহার না করা যায়
      await firestore.collection('completed_transactions').add({
        'transactionId': transactionId,
        'productId': purchase.productID,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Transaction Verification Error: $e");
      return false;
    }
  }

  // সার্ভার ভেরিফিকেশন ফাংশন
  Future<bool> _verifyWithServer(PurchaseDetails purchase, int amount) async {
    const String cloudFunctionUrl = "https://verifyandadddiamonds-phdlxpvakq-uc.a.run.app";

    try {
      // সঠিক ফায়ারস্টোর ডকুমেন্ট আইডি বের করা
      final user = FirebaseAuth.instance.currentUser;
      String? firestoreDocId;
      
      if (user != null) {
        final collection = FirebaseFirestore.instance.collection('users');
        QuerySnapshot query = await collection.where('authUID', isEqualTo: user.uid).limit(1).get();
        if (query.docs.isEmpty && user.email != null) {
          query = await collection.where('email', isEqualTo: user.email).limit(1).get();
        }
        if (query.docs.isEmpty) {
          query = await collection.where('uID', isEqualTo: user.uid).limit(1).get();
        }
        if (query.docs.isNotEmpty) {
          firestoreDocId = query.docs.first.id; // যেমন: "978051"
        }
      }

      final userIdToSend = firestoreDocId ?? widget.userData['uID'] ?? user?.uid;
      final txnIdToSend = purchase.purchaseID ?? 
          (purchase.verificationData.serverVerificationData.isNotEmpty 
              ? purchase.verificationData.serverVerificationData.substring(0, purchase.verificationData.serverVerificationData.length > 20 ? 20 : purchase.verificationData.serverVerificationData.length) 
              : "unknown");

      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "purchaseToken": purchase.verificationData.serverVerificationData,
          "productId": purchase.productID,
          "userId": userIdToSend, // এখন সঠিক ডকুমেন্ট আইডি যাবে
          "amount": amount,
          "transactionId": txnIdToSend,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Server verification failed: $e");
      return false;
    }
  }

  // পেমেন্ট শুরু করার ফাংশন
  Future<void> _initiatePurchase(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Store is not available right now.")),
        );
      }
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails({productId});

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);

      _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product not found in the store.")),
        );
      }
    }
  }

  // ফায়ারবেস আপডেট ও হিস্টোরি লজিক
  Future<void> _updateUserDiamonds(int amount, String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collection = FirebaseFirestore.instance.collection('users');

    QuerySnapshot query =
        await collection.where('authUID', isEqualTo: user.uid).limit(1).get();

    if (query.docs.isEmpty && user.email != null) {
      query =
          await collection.where('email', isEqualTo: user.email).limit(1).get();
    }

    if (query.docs.isEmpty) {
      query = await collection.where('uID', isEqualTo: user.uid).limit(1).get();
    }

    if (query.docs.isNotEmpty) {
      final userDoc = query.docs.first;
      final String receiverFirestoreId = userDoc.id;
      final DocumentReference receiverRef = collection.doc(receiverFirestoreId);

      int earnedXP = amount ~/ 250;
      if (earnedXP < 1) earnedXP = 1;

      try {
        // ১. ইউজারের মেইন ডক আপডেট
        await receiverRef.update({
          'diamonds': FieldValue.increment(amount),
          'vip_xp': FieldValue.increment(earnedXP),
        });

        // ২. ইনবক্সে অফিশিয়াল মেসেজ পাঠানো
        String chatId = "paglachat_official_$receiverFirestoreId";
        DocumentReference chatDocRef =
            FirebaseFirestore.instance.collection('chats').doc(chatId);
        DocumentReference msgRef = chatDocRef.collection('messages').doc();

        Map<String, dynamic> officialMsg = {
          'senderId': 'paglachat_official',
          'receiverId': receiverFirestoreId,
          'text':
              "🎉 You've received $amount Diamonds and $earnedXP XP bonus from Google Play Recharge.",
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'system_msg'
        };

        await msgRef.set(officialMsg);

        await chatDocRef.set({
          'lastMessage': "🎉 Received $amount Diamonds",
          'lastTimestamp': FieldValue.serverTimestamp(),
          'users': ['paglachat_official', receiverFirestoreId],
          'unReadCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // ৩. রিচার্জ হিস্টোরি সেভ
        DocumentReference rechargeRef =
            receiverRef.collection('recharge_history').doc();
        await rechargeRef.set({
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'method': 'Google Play Store',
          'status': 'Success',
          'transactionId': transactionId,
        });
      } catch (e) {
        debugPrint("Error updating database: ${e.toString()}");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success! $amount Diamonds & $earnedXP XP added."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.lightBlue.shade200,
            Colors.blue.shade50,
            Colors.white
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          ...List.generate(
              20,
              (index) => Positioned(
                  top: (index * 45.0) % 500,
                  left: (index * 75.0) % 400,
                  child: Icon(Icons.star,
                      size: index % 3 == 0 ? 12 : 6,
                      color: Colors.white.withOpacity(0.8)))),
          Column(
            children: [
              const SizedBox(height: 12),
              _buildBanner(),
              Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text("Diamond Store",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const Divider(
                  color: Colors.blueAccent,
                  thickness: 0.5,
                  indent: 50,
                  endIndent: 50),
              Expanded(
                child: Column(
                  children: [
                    if (widget.isAgent) _buildAgentCard(),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _diamondPacks.length,
                        itemBuilder: (context, index) {
                          String key = _diamondPacks.keys.elementAt(index);
                          var item = _diamondPacks[key]!;
                          return DiamondGridItem(
                            display: item['display'],
                            price: item['price'],
                            onTap: () =>
                                _showPaymentMethods(item['amount'], key),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: CachedNetworkImageProvider(
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/daimondbenar.jpg",
          ),
          fit: BoxFit.cover,
        ),
        border: Border.all(
          color: Colors.amber.shade700,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildAgentCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF60404), Color(0xFFFC0C03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF60404).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.amberAccent, size: 32),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Agency Wallet",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                      Text(
                        "Transfer diamonds to users",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified, color: Colors.cyanAccent, size: 24),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AgentTransferPage()),
                  );
                },
                icon: const Icon(Icons.stars_rounded,
                    size: 22, color: Colors.white),
                label: const Text(
                  "DIAMOND SELLING",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.white38)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(int diamondAmount, String productId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.blue),
            title:
                const Text("Google Pay", style: TextStyle(color: Colors.white)),
            subtitle: Text("Buy $diamondAmount Diamonds",
                style: const TextStyle(color: Colors.white54)),
            onTap: () {
              Navigator.pop(context);
              _initiatePurchase(productId);
            },
          ),
        ],
      ),
    );
  }
}