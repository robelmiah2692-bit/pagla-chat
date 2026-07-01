import 'package:flutter/material.dart';

class VIPBenefitsScreen extends StatelessWidget {
  const VIPBenefitsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("VIP Benefits")),
      body: const Center(child: Text("VIP Levels and Rewards here")),
    );
  }
}