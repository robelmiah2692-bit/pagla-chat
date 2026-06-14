import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: dependence_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // কনসিউম করার জন্য জরুরি
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  };

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _handlePurchaseUpdates(purchaseDetailsList);
    }, onDone: () => _subscription?.cancel(), onError: (error) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // পেমেন্ট হ্যান্ডেলার (সবচেয়ে গুরুত্বপূর্ণ ফিক্স)
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        int? diamondsToAdd = _diamondPacks[purchase.productID]?['amount'];
        if (diamondsToAdd != null) {
          // ১. ফায়ারবেসে ডায়মন্ড প্লাস করা হচ্ছে
          await _updateUserDiamonds(diamondsToAdd);
        }

        // ২. এন্ড্রয়েডের জন্য পারচেজটি কনসিউম (খালি) করা হচ্ছে যাতে বারবার কেনা যায়
        final InAppPurchaseAndroidPlatformAddition androidAddition =
            _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(purchase);

        // ৩. গুগলকে জানানো যে ট্রানজেকশন সফলভাবে শেষ হয়েছে
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // কোনো এরর আসলে এখানে হ্যান্ডেল হবে (আপাতত ফাঁকা)
        debugPrint("Purchase Error: ${purchase.error.toString()}");
      }
    }
  }

  // পেমেন্ট শুরু (One-time product এর জন্য ফিক্স)
  Future<void> _initiatePurchase(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) return;

    final ProductDetailsResponse response =
        await _iap.queryProductDetails({productId});

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);

      // কনসোলের One-time product এর জন্য buyNonConsumable ব্যবহার করতে হবে,
      // পরে কোডের ভেতরে আমরা সেটাকে অ্যান্ড্রয়েড লেভেলে ম্যানুয়ালি consume করে দেব।
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  // ফায়ারবেস আপডেট (পুরাতন এজেন্সী ট্রান্সফারের হুবহু লজিক অনুযায়ী)
  Future<void> _updateUserDiamonds(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final collection = FirebaseFirestore.instance.collection('users');

    // ১. প্রথমে authUID দিয়ে চেক
    QuerySnapshot query =
        await collection.where('authUID', isEqualTo: user.uid).limit(1).get();

    // ২. যদি না পায়, তবে ইমেইল দিয়ে চেক
    if (query.docs.isEmpty && user.email != null) {
      query =
          await collection.where('email', isEqualTo: user.email).limit(1).get();
    }

    // ৩. যদি তবুও না পায়, তবে uID দিয়ে চেক
    if (query.docs.isEmpty) {
      query = await collection.where('uID', isEqualTo: user.uid).limit(1).get();
    }

    if (query.docs.isNotEmpty) {
      final userDoc = query.docs.first;
      final String receiverFirestoreId =
          userDoc.id; // ইউজারের আসল ফায়ারস্টোর ডকুমেন্ট আইডি
      final DocumentReference receiverRef = collection.doc(receiverFirestoreId);

      // এজেন্সী লজিক অনুযায়ী এক্সপি হিসাব: প্রতি ২৫০ ডায়মন্ডে ১ এক্সপি
      int earnedXP = amount ~/ 250;
      if (earnedXP < 1)
        earnedXP = 1; // প্যাকের দাম কম হলেও যেন মিনিমাম ১ এক্সপি পায়

      // রাইট অপারেশনগুলো ট্রানজেকশন বা নরমাল ব্যাচ ছাড়াই সেফলি রান করা হচ্ছে
      try {
        // ১. ইউজারের মেইন ডক আপডেট (ডায়মন্ড এবং ভিআইপি এক্সপি)
        await receiverRef.update({
          'diamonds': FieldValue.increment(amount),
          'vip_xp':
              FieldValue.increment(earnedXP), // এজেন্সির মতো হুবহু vip_xp ফিল্ড
        });

        // ২. ইউজারের ইনবক্সে অফিশিয়াল মেসেজ পাঠানো (পাগলাচ্যাট অফিশিয়াল চ্যাট আইডি লজিক)
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
          'type': 'system_msg' // এজেন্সির মতো হুবহু টাইপ
        };

        await msgRef.set(officialMsg);

        // চ্যাট লিস্টে মেসেজটি পুশ করা
        await chatDocRef.set({
          'lastMessage': "🎉 Received $amount Diamonds",
          'lastTimestamp': FieldValue.serverTimestamp(),
          'users': ['paglachat_official', receiverFirestoreId],
          'unReadCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // ৩. ইউজারের নিজস্ব রিচার্জ হিস্টোরি সাব-কালেকশনে ডাটা সেভ
        DocumentReference rechargeRef =
            receiverRef.collection('recharge_history').doc();
        await rechargeRef.set({
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'method': 'Google Play Store', // মেথডের নাম প্লে স্টোর
          'status': 'Success'
        });
      } catch (e) {
        debugPrint(
            "Error updating database with agency logic: ${e.toString()}");
      }

      // স্ক্রিনে সফলতার ফ্ল্যাশকার্ড বা মেসেজ
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
    print("DEBUG: Full UserData: ${widget.userData}");
    print("DEBUG: Is Agent Value: ${widget.isAgent}");
    print("DEBUG: Is Agent Type: ${widget.isAgent.runtimeType}");

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
                        color: Colors.white.withOpacity(0.8)),
                  )),
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
                          crossAxisCount: 2, // এক সারিতে ২টা কার্ড
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
            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/daimondbenar.png",
          ),
          fit: BoxFit
              .cover, // ব্যানারটি ভালোভাবে দেখানোর জন্য cover ব্যবহার করলাম
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

  Widget _buildDiamondOption(
      String display, String price, String prodId, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: InkWell(
        onTap: () => _showPaymentMethods(amount, prodId),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: Colors.blueAccent, size: 26),
                const SizedBox(width: 15),
                Expanded(
                    child: Text(display,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.bold))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15)),
                  child: Text(price,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
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
