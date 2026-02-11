import 'package:flutter/material.dart';

class SeatWidget extends StatelessWidget {
  final int index;
  final bool isSpeaking;

  const SeatWidget({super.key, required this.index, this.isSpeaking = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isSpeaking)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                ),
              ),
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white10,
              child: Icon(Icons.chair_outlined, color: Colors.white24, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text("${index + 1}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
