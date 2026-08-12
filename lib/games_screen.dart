import 'dart:async'; // 🛠️ স্ট্রিম সাবস্ক্রিপশনের জন্য এটি লাগবে
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagla_chat/crazy_fruit_game.dart';
import 'lucky_spin_view.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int userBalance = 0;
  String? _userDocId;
  final String _roomId = "global_room";
  StreamSubscription<DocumentSnapshot>? _balanceSubscription; // 🛠️ মেমরি লিক রোধে সাবস্ক্রিপশন ভেরিয়েবল

  @override
  void initState() {
    super.initState();
    _findUserDocument();
  }

  @override
  void dispose() {
    _balanceSubscription?.cancel(); // 🛠️ পেজ বন্ধ হলে লিসেনার ক্যানসেল করে দেওয়া হলো
    super.dispose();
  }

  // ডাটা মুছে যাওয়া এড়াতে এখানে শুধু ডাটা রিড করা হচ্ছে
  void _findUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        setState(() {
          _userDocId = query.docs.first.id;
        });
        _listenToBalance();
      }
    }
  }

  void _listenToBalance() {
    if (_userDocId == null) return;

    // 🛠️ সাবস্ক্রিপশন ভেরিয়েবলে স্টোর করা হলো যাতে পরে ডিসপোজ করা যায়
    _balanceSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userDocId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data();
        if (data != null) {
          setState(() {
            // ডায়মন্ড ডাটা ইন্টিজার বা স্ট্রিং যাই হোক না কেন নিরাপদে হ্যান্ডেল করবে
            var diamondVal = data['diamonds'];
            if (diamondVal is int) {
              userBalance = diamondVal;
            } else {
              userBalance = int.tryParse(diamondVal?.toString() ?? "0") ?? 0;
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Games"),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              const Icon(Icons.diamond, color: Colors.cyanAccent),
              Text(" $userBalance",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _gameIcon("CRAZY FRUIT", "assets/images/crazyfrut.png",
                      Colors.yellow),
                  _gameIcon("LUCKY", "assets/images/spin_logo.png",
                      Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameIcon(String name, String asset, Color color) {
    return GestureDetector(
      onTap: () {
        if (_userDocId == null) return;

        if (name == "CRAZY FRUIT") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CrazyFruitGame(
                        userBalance: userBalance,
                        onUpdateBalance: (newBalance) {
                          // 🛠️ স্ট্রিংয়ের বদলে সরাসরি ইন্টিজার হিসেবে সেভ করা নিরাপদ
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_userDocId)
                              .update({'diamonds': newBalance});
                        },
                      )));
        } else if (name == "LUCKY") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LuckySpinView(
                        gameRef:
                            FirebaseDatabase.instance.ref("games/$_roomId"),
                        userRef: FirebaseDatabase.instance.ref(
                            "users/${FirebaseAuth.instance.currentUser?.uid}"),
                        userBalance: userBalance,
                        betAmount: 100,
                        luckyBets: const [],
                        playSound: (url) {},
                      )));
        }
      },
      child: Column(
        children: [
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withOpacity(0.5))),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(asset, fit: BoxFit.cover)),
          )),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}