import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class DailyBonusPopup {
  static void show(BuildContext context, String uID) async {
    if (uID.isEmpty) {
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(uID);
    
    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return;
      }

      bool canClaim = true;
      final data = snapshot.data();
      
      if (data != null && data.containsKey('daily_bonus')) {
        var lastBonusTime = data['daily_bonus'];
        int lastTime = 0;
        
        if (lastBonusTime is Timestamp) {
          lastTime = lastBonusTime.millisecondsSinceEpoch;
        } else if (lastBonusTime is int) {
          lastTime = lastBonusTime;
        } else if (lastBonusTime is String) {
          lastTime = int.tryParse(lastBonusTime) ?? 0;
        }

        // ২৪ ঘণ্টা (৮৬৪০০০০০ মিলিগ্রাম) পার হয়েছে কিনা চেক
        if (DateTime.now().millisecondsSinceEpoch - lastTime < 86400000) {
          canClaim = false;
        }
      }

      if (canClaim) {
        if (!context.mounted) return;
        
        // ডাবল ট্যাপ রোধ করতে স্টেটফুল উইজেট বা স্টেট ম্যানেজমেন্টের মতো ডায়ালগের ভেতরে স্টেট হ্যান্ডেল করা
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _DailyBonusDialog(docRef: docRef),
        );
      }
    } catch (e) {
      // সাইলেন্টলি হ্যান্ডেল করা হলো
    }
  }
}

// আলাদা স্টেটফুল উইজেট ডাবল ক্লিক ও লোডিং হ্যান্ডেল করার জন্য
class _DailyBonusDialog extends StatefulWidget {
  final DocumentReference docRef;
  const _DailyBonusDialog({required this.docRef});

  @override
  State<_DailyBonusDialog> createState() => _DailyBonusDialogState();
}

class _DailyBonusDialogState extends State<_DailyBonusDialog> {
  bool _isClaiming = false;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Daily Bonus",
                style: TextStyle(
                  color: Color.fromARGB(255, 104, 230, 247),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 15),
              Lottie.network(
                'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/animation.json',
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 10),
              const Text(
                "50 Diamonds",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _isClaiming
                  ? const CircularProgressIndicator(color: Colors.amberAccent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () async {
                        if (_isClaiming) return; // মাল্টিপল ক্লিক প্রিভেন্ট করার জন্য
                        setState(() {
                          _isClaiming = true;
                        });

                        try {
                          // ফায়ারস্টোরে নিখুঁতভাবে একসাথে ৫০ ডায়মন্ড increment এবং টাইম আপডেট করা
                          await widget.docRef.update({
                            'diamonds': FieldValue.increment(50),
                            'daily_bonus': DateTime.now().millisecondsSinceEpoch,
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              _isClaiming = false;
                            });
                          }
                        }
                      },
                      child: const Text(
                        "GET",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}