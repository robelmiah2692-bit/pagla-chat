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

  @override
  void initState() {
    super.initState();
    _findUserDocument();
  }

  // ডাটা মুছে যাওয়া এড়াতে এখানে শুধু ডাটা রিড করা হচ্ছে
  void _findUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // আপনার ডাটাবেস অনুযায়ী authUID ফিল্ড দিয়ে খুঁজে আইডি বের করছি
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: user.uid)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _userDocId = query.docs.first.id;
        });
        _listenToBalance();
      }
    }
  }

  void _listenToBalance() {
    if (_userDocId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userDocId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data();
        if (data != null) {
          setState(() {
            // ডাটাবেসের ফিল্ডের নাম 'diamonds' নিশ্চিত হয়ে নিন
            userBalance =
                int.tryParse(data['diamonds']?.toString() ?? "0") ?? 0;
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
                          // শুধুমাত্র ব্যালেন্স আপডেট করছে, পুরো ইউজার ডাটা নয়
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_userDocId)
                              .update({'diamonds': newBalance.toString()});
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
