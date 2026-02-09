import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaglaChatSignPage(),
    ));

class PaglaChatSignPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A0033), // লোগোর থিম কালার
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // আপনার লোগো (assets ফোল্ডারে logo.jpg নামে থাকতে হবে)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo.jpg',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.mic, size: 100, color: Colors.purpleAccent),
              ),
            ),
            SizedBox(height: 40),
            Text("Pagla Chat", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Live Voice Adda", style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 50),
            
            // সাইন ইন বাটন
            ElevatedButton.icon(
              icon: Icon(Icons.phone_android, color: Colors.white),
              label: Text("Sign In with Mobile", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                // এখানে পরে লগইন সিস্টেম যোগ হবে
              },
            ),
          ],
        ),
      ),
    );
  }
}
