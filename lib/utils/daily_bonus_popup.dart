import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class DailyBonusPopup {
  static void show(BuildContext context, String uID) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uID);
    final snapshot = await docRef.get();

    bool canClaim = true;
    if (snapshot.exists && snapshot.data()!.containsKey('daily_bonus')) {
      int lastTime = snapshot.data()!['daily_bonus'];
      if (DateTime.now().millisecondsSinceEpoch - lastTime < 86400000) {
        canClaim = false;
      }
    }

    if (canClaim) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // ব্লার ইফেক্ট
          child: Dialog(
            backgroundColor: Colors.transparent, // স্বচ্ছ ব্যাকগ্রাউন্ড
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // গ্লাস ইফেক্ট কালার
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 20)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Daily Bonus",
                      style: TextStyle(
                          color: const Color.fromARGB(255, 104, 230, 247),
                          fontWeight: FontWeight.bold,
                          fontSize: 24)),
                  SizedBox(height: 15),
                  Lottie.network(
                    'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/animation.json',
                    height: 150,
                    width: 150,
                  ),
                  SizedBox(height: 10),
                  Text("50 Diamonds",
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      shape: StadiumBorder(),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    onPressed: () async {
                      try {
                        int currentDiamonds = snapshot.exists
                            ? (snapshot.data()!['diamonds'] ?? 0)
                            : 0;
                        await docRef.update({
                          'diamonds': currentDiamonds + 50,
                          'daily_bonus': DateTime.now().millisecondsSinceEpoch,
                        });
                        Navigator.pop(context);
                      } catch (e) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text("GET",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
