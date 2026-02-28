import 'package:flutter/material.dart';

class GamePanelView extends StatefulWidget {
  const GamePanelView({super.key});

  @override
  State<GamePanelView> createState() => _GamePanelViewState();
}

class _GamePanelViewState extends State<GamePanelView> {
  int diamondBet = 50; 
  bool isGameStarted = false; // গেম শুরু হয়েছে কি না
  String selectedGame = "";   // কোন গেমটি খেলছে

  void _updateBet(int amount) {
    setState(() {
      if (diamondBet + amount >= 50) {
        diamondBet += amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // মিডিয়া কুয়েরি দিয়ে স্ক্রিনের অর্ধেক উচ্চতা নিচ্ছি
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withAlpha(50), side: const BorderSide(color: Colors.cyanAccent)),
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

  // ২. গেম ইন্টারফেস (হাফ স্ক্রিনে গেম চলবে)
  Widget _buildGameInterface() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("$selectedGame Playing...", style: const TextStyle(fontSize: 14)),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => isGameStarted = false)),
          actions: [
            Center(child: Text("💎 $diamondBet  ", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selectedGame == "LUDO" ? Icons.grid_on_rounded : Icons.casino, size: 80, color: Colors.white24),
                const SizedBox(height: 20),
                const Text("Game Animation Loading...", style: TextStyle(color: Colors.white54)),
                // এখানে আপনার লুডু বা লাকি গেমের লজিক বসবে
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gameCard(String name, IconData icon, Color color) {
    bool isSelected = selectedGame == name;
    return GestureDetector(
      onTap: () => setState(() => selectedGame = name),
      child: Container(
        width: 120,
        height: 120,
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
