import 'package:flutter/material.dart';

class VSPKView extends StatelessWidget {
  const VSPKView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.6), Colors.red.withOpacity(0.6)]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: const Center(
        child: Text(
          "TEAM VS BATTLE MODE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
    );
  }
}
