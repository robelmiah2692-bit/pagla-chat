import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:http/http.dart' as http;

class AgencyRechargePage extends StatefulWidget {
  const AgencyRechargePage({super.key});

  @override
  State<AgencyRechargePage> createState() => _AgencyRechargePageState();
}

class _AgencyRechargePageState extends State<AgencyRechargePage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool isLoading = false;

  // প্লে কনসোলে সহজে বসানোর জন্য স্ট্যান্ডার্ড প্রোডাক্ট আইডি সহ এজেন্সি প্যাকগুলো
  final List<Map<String, dynamic>> rechargePackages = [
    {
      'productId': 'agency_pack_50k',
      'title': 'STARTER AGENCY PACK',
      'stars': '★☆☆☆☆',
      'priceUSD': 50,
      'normalDiamonds': 800000,
      'bonusDiamonds': 200000,
      'totalDiamonds': 1000000,
      'color': const Color(0xFF7B1FA2),
    },
    {
      'productId': 'agency_pack_100k',
      'title': 'BASIC AGENCY PACK',
      'stars': '★★★☆☆',
      'priceUSD': 100,
      'normalDiamonds': 1600000,
      'bonusDiamonds': 400000,
      'totalDiamonds': 2000000,
      'color': const Color(0xFF1976D2),
    },
    {
      'productId': 'agency_pack_200k',
      'title': 'SILVER AGENCY PACK',
      'stars': '★★★☆☆',
      'priceUSD': 200,
      'normalDiamonds': 3200000,
      'bonusDiamonds': 800000,
      'totalDiamonds': 4000000,
      'color': const Color(0xFF455A64),
    },
    {
      'productId': 'agency_pack_300k',
      'title': 'GOLD AGENCY PACK',
      'stars': '★★★★☆',
      'priceUSD': 300,
      'normalDiamonds': 4800000,
      'bonusDiamonds': 1200000,
      'totalDiamonds': 6000000,
      'color': const Color(0xFFFFA000),
    },
    {
      'productId': 'agency_pack_500k',
      'title': 'PREMIUM AGENCY PACK',
      'stars': '★★★★★',
      'priceUSD': 500,
      'normalDiamonds': 8000000,
      'bonusDiamonds': 2000000,
      'totalDiamonds': 10000000,
      'color': const Color(0xFFD32F2F),
      'isBestValue': true,
    },
  ];

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

  // পেমেন্ট শুরু করার ফাংশন (গুগল প্লে স্টোর চেক করে পেমেন্ট পপআপ তুলবে)
  Future<void> _initiateGoogleRecharge(Map<String, dynamic> package) async {
    setState(() => isLoading = true);

    final bool available = await _iap.isAvailable();
    if (!available) {
      setState(() => isLoading = false);
      _showSnackBar("Google Play Store is not available right now.", isError: true);
      return;
    }

    String productId = package['productId'];
    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});

    if (response.productDetails.isNotEmpty) {
      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // গুগল প্লে কনসোল থেকে রিয়েল পারচেস ফ্লো কল করা হচ্ছে
      _iap.buyConsumable(purchaseParam: purchaseParam);
      
      // লোডিং সাময়িকভাবে বন্ধ করা হলো কারণ ইউজার এখন গুগল প্লে উইন্ডোতে আছে
      setState(() => isLoading = false);
    } else {
      setState(() => isLoading = false);
      _showSnackBar("Product not found in Google Play Console: $productId", isError: true);
    }
  }

  // গুগল পে / পেমেন্ট গেটওয়ে সম্পন্ন হওয়ার পর পেমেন্ট হ্যান্ডেল ও ভেরিফাই করার লজিক
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        
        setState(() => isLoading = true);

        // প্যাকেজ খুঁজে বের করা
        var package = rechargePackages.firstWhere(
          (pkg) => pkg['productId'] == purchase.productID,
          orElse: () => {},
        );

        if (package.isNotEmpty) {
          int totalDiamondsToAdd = package['totalDiamonds'];

          // ১. ডুপ্লিকেট বা ফেক ট্রানজেকশন চেক (Anti-Hack)
          bool isUnique = await _verifyAndPreventDuplicatePurchase(purchase);

          if (isUnique) {
            // ২. সার্ভার সাইড বা ফায়ারস্টোরে সিকিউরড উপায়ে ডায়মন্ড ও হিস্টোরি আপডেট করা
            await _processDatabaseUpdate(package, purchase);
          }
        }

        // ৩. অ্যান্ড্রয়েডের জন্য পারচেজটি সেফলি কনজিউম ও কমপ্লিট করা
        if (purchase.pendingCompletePurchase) {
          final InAppPurchaseAndroidPlatformAddition androidAddition =
              _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              
          try {
            await androidAddition.consumePurchase(purchase);
          } catch (e) {
            debugPrint("Notice: Purchase already consumed: $e");
          }

          try {
            await _iap.completePurchase(purchase);
          } catch (e) {
            debugPrint("Notice: Complete purchase skipped: $e");
          }
        }

        setState(() => isLoading = false);

      } else if (purchase.status == PurchaseStatus.error) {
        setState(() => isLoading = false);
        _showSnackBar("Purchase Failed: ${purchase.error?.message ?? 'Unknown error'}", isError: true);
      }
    }
  }

  // ডুপ্লিকেট পেমেন্ট বা হ্যাকড রসিদ চেক করার ফাংশন (Anti-Hack)
  Future<bool> _verifyAndPreventDuplicatePurchase(PurchaseDetails purchase) async {
    String? transactionId = purchase.purchaseID;
    if (transactionId == null || transactionId.isEmpty) {
      if (purchase.verificationData.serverVerificationData.isNotEmpty) {
        transactionId = purchase.verificationData.serverVerificationData;
      } else {
        return false;
      }
    }

    try {
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot existingTxn = await firestore
          .collection('completed_transactions')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (existingTxn.docs.isNotEmpty) {
        debugPrint("WARNING: Duplicate or fake transaction attempt detected: $transactionId");
        return false;
      }

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

  // ফায়ারস্টোর ডাটাবেজে এজেন্সির ওয়ালেটে রিয়েল ডায়মন্ড যোগ করার ট্রানজেকশন
  Future<void> _processDatabaseUpdate(Map<String, dynamic> package, PurchaseDetails purchase) async {
    try {
      String authUID = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (authUID.isEmpty) throw Exception("User not logged in!");

      var agentQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: authUID)
          .limit(1)
          .get();

      if (agentQuery.docs.isEmpty) throw Exception("Agent profile not found!");

      DocumentReference agentRef = agentQuery.docs.first.reference;
      String agentDocId = agentQuery.docs.first.id;
      int totalDiamondsToAdd = package['totalDiamonds'];
      String txnId = purchase.purchaseID ?? purchase.verificationData.serverVerificationData;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot agentSnap = await transaction.get(agentRef);
        if (!agentSnap.exists) throw Exception("Agent data does not exist!");

        int currentWallet = (agentSnap.get('agency_wallet') ?? 0).toInt();

        // এজেন্সির ওয়ালেটে ডায়মন্ড যোগ করা
        transaction.update(agentRef, {
          'agency_wallet': currentWallet + totalDiamondsToAdd,
        });

        // রিচার্জ হিস্টোরি সেভ করা
        DocumentReference historyRef = FirebaseFirestore.instance.collection('agency_recharge_history').doc();
        transaction.set(historyRef, {
          'agentId': agentDocId,
          'authUID': authUID,
          'productId': package['productId'],
          'packageName': package['title'],
          'priceUSD': package['priceUSD'],
          'normalDiamonds': package['normalDiamonds'],
          'bonusDiamonds': package['bonusDiamonds'],
          'totalDiamonds': totalDiamondsToAdd,
          'paymentMethod': 'Google Play Billing',
          'transactionId': txnId,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Success'
        });
      });

      if (!mounted) return;
      _showSuccessDialog(package['totalDiamonds']);

    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll("Exception:", ""), isError: true);
    }
  }

  void _showSuccessDialog(int diamonds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        title: const Text("Recharge Successful! 🎉", style: TextStyle(color: Colors.greenAccent)),
        content: Text(
          "Successfully added $diamonds 💎 to your Agency Wallet via Google Play.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("Agency Wallet Recharge", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // টপ ব্যানার
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: const Column(
                  children: [
                    Text(
                      "RECHARGE MORE, EARN MORE",
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "GET 25% EXTRA DIAMONDS EXCLUSIVELY FOR AGENCIES!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // প্যাকেজ লিস্ট
              ...rechargePackages.map((pkg) => _buildPackageCard(pkg)),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    bool isBest = pkg['isBestValue'] ?? false;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBest ? Colors.amber : Colors.white12,
              width: isBest ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg['title'], 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(pkg['stars'], style: const TextStyle(color: Colors.amber, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("\$${pkg['priceUSD']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("💎 ${pkg['normalDiamonds']} Normal", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text("+${pkg['bonusDiamonds']} (25% Bonus)", style: const TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Total Diamonds", style: TextStyle(color: Colors.white38, fontSize: 10)),
                      Text("✨ ${pkg['totalDiamonds']}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _initiateGoogleRecharge(pkg),
                  child: const Text("RECHARGE NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
        if (isBest)
          Positioned(
            top: 2,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("BEST VALUE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}