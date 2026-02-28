import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GamePanelView extends StatefulWidget {
  const GamePanelView({super.key});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  int diamondBet = 50; 
  bool isGameStarted = false; // গেম শুরু হয়েছে কি না
  String selectedGame = "";   // কোন গেমটি খেলছে
  
  // গেমের লজিক ভেরিয়েবল
  int diceNumber = 1;
  bool isActionInProgress = false; 

  void _updateBet(int amount) {
    setState(() {
      if (diamondBet + amount >= 50) {
        diamondBet += amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double halfHeight = MediaQuery.of(context).size.height * 0.55;

    return Container(
      height: halfHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
      ),
      child: isGameStarted ? _buildGameInterface() : _buildGameSelection(),
    );
  }

  // ১. গেম সিলেকশন স্ক্রিন
  Widget _buildGameSelection() {
    return Column(
      children: [
        const SizedBox(height: 15),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 15),
        const Text("SELECT GAME", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _gameCard("LUDO", Icons.grid_on_rounded, Colors.orange),
              _gameCard("LUCKY", Icons.casino, Colors.green),
            ],
          ),
        ),

        _betControlArea(),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withAlpha(50), 
                side: const BorderSide(color: Colors.cyanAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () {
                if (selectedGame.isNotEmpty) {
                  setState(() => isGameStarted = true);
                }
              },
              child: const Text("START GAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  // ২. গেম ইন্টারফেস (হাফ স্ক্রিন)
  Widget _buildGameInterface() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("$selectedGame MODE", style: const TextStyle(fontSize: 14, color: Colors.cyanAccent)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white), 
            onPressed: () => setState(() {
              isGameStarted = false;
              isActionInProgress = false;
            })
          ),
          actions: [
            Center(child: Text("💎 $diamondBet  ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ],
        ),
        Expanded(
          child: Center(
            child: selectedGame == "LUDO" ? _buildLudoContent() : _buildLuckyContent(),
          ),
        ),
      ],
    );
  }

  // --- লজিক: লুডু ডাইস ---
  Widget _buildLudoContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: isActionInProgress ? null : _rollDice,
          child: AnimatedRotation(
            turns: isActionInProgress ? 2 : 0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Icon(_getDiceIcon(diceNumber), size: 80, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(isActionInProgress ? "Rolling..." : "Tap to Roll Dice", style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  // --- লজিক: লাকি স্পিন ---
  Widget _buildLuckyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: isActionInProgress ? 10 : 0),
          duration: const Duration(seconds: 3),
          builder: (context, double value, child) {
            return Transform.rotate(
              angle: value * pi,
              child: const Icon(Icons.stars_rounded, size: 120, color: Colors.amberAccent),
            );
          },
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isActionInProgress ? Colors.grey : Colors.green),
          onPressed: isActionInProgress ? null : _startLuckySpin,
          child: Text(isActionInProgress ? "Spinning..." : "SPIN NOW"),
        ),
      ],
    );
  }

  // --- মেথড সমূহ (আপডেটেড উইনিং লজিক সহ) ---

  void _rollDice() {
    setState(() => isActionInProgress = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // ১০% সম্ভাবনা ৬ পড়ার, বাকি সময় ১-৫ পড়বে
        int rollChance = Random().nextInt(100);
        if (rollChance < 10) { 
          diceNumber = 6;
        } else {
          diceNumber = Random().nextInt(5) + 1;
        }
        isActionInProgress = false;
      });

      if (diceNumber == 6) {
        _showResultDialog("LUDO MASTER!", "৬ পড়েছে! আপনি বোনাস ডায়মন্ড জিতেছেন!");
      }
    });
  }

  void _startLuckySpin() {
    setState(() => isActionInProgress = true);

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isActionInProgress = false;
        
        // ৩০% জেতার সম্ভাবনা, ৭০% আপনার লাভ
        int winChance = 30;  
        int randomNumber = Random().nextInt(100); 
        bool isWin = randomNumber < winChance; 

        if (isWin) {
          int winningAmount = diamondBet * 2; 
          _showResultDialog("WINNER! 🎉", "অভিনন্দন! আপনি $winningAmount ডায়মন্ড জিতেছেন।");
        } else {
          _showResultDialog("LOST", "দুঃখিত! আপনি $diamondBet ডায়মন্ড হেরেছেন। আবার চেষ্টা করুন।");
        }
      });
    });
  }

  void _showResultDialog(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("OK", style: TextStyle(color: Colors.cyanAccent))
          )
        ],
      ),
    );
  }

  IconData _getDiceIcon(int num) {
    List<IconData> icons = [Icons.looks_one, Icons.looks_two, Icons.looks_3, Icons.looks_4, Icons.looks_5, Icons.looks_6];
    return icons[num - 1];
  }

  Widget _gameCard(String name, IconData icon, Color color) {
    bool isSelected = selectedGame == name;
    return GestureDetector(
      onTap: () => setState(() => selectedGame = name),
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white12, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _betControlArea() {
    return Column(
      children: [
        const Text("Bet Amount", style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => _updateBet(-50)),
            Text("💎 $diamondBet", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.greenAccent), onPressed: () => _updateBet(50)),
          ],
        ),
      ],
    );
  }
}
