import 'package:flutter/material.dart';

class SeatWidget extends StatelessWidget {
  final int index;
  final bool isSpeaking;

  const SeatWidget({required this.index, this.isSpeaking = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // স্পিকিং এনিমেশন বর্ডার (যদি কথা বলে)
            if (isSpeaking)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                ),
              ),
            // মেইন সিট
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.1),
              child: Icon(Icons.chair_rounded, color: Colors.white24, size: 20),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text("${index + 1}", style: TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
