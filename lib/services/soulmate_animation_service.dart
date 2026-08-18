import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  static Widget buildSoulmateHeartOverlay({
    required List<dynamic> seats,
    required Map<String, List<dynamic>> allUsersSoulmates,
  }) {
    List<Widget> hearts = [];
    Set<String> processedPairs = {};

    for (int i = 0; i < seats.length; i++) {
      var seatA = seats[i];
      if (seatA == null || seatA['uID'] == null) continue;
      String uidA = seatA['uID'].toString();

      List<dynamic> soulmatesA = allUsersSoulmates[uidA] ?? [];

      for (int j = 0; j < seats.length; j++) {
        var seatB = seats[j];
        if (seatB == null || seatB['uID'] == null) continue;
        String uidB = seatB['uID'].toString();

        if ((i - j).abs() == 1 && (i ~/ 4 == j ~/ 4)) {
          if (soulmatesA.contains(uidB)) {
            String pairId = (i < j) ? "$i-$j" : "$j-$i";
            if (!processedPairs.contains(pairId)) {
              hearts.add(_createHeartWidget(i, j));
              processedPairs.add(pairId);
            }
          }
        }
      }
    }
    // RepaintBoundary দিয়ে র‍্যাপ করলে অ্যানিমেশনের কারণে পুরো রুম রি-রেন্ডার হয়ে হ্যাং করবে না
    return RepaintBoundary(child: Stack(children: hearts));
  }

  static Widget _createHeartWidget(int index1, int index2) {
    int leftSeat = (index1 < index2) ? index1 : index2;
    int row = leftSeat ~/ 4;
    int col = leftSeat % 4;

    return Builder(builder: (context) {
      double totalWidth = MediaQuery.of(context).size.width - 32;
      double colWidth = totalWidth / 4;
      double seatHeight = colWidth / 0.75;

      return Positioned(
        left: 16 + (col * colWidth) + (colWidth - 70),
        top: (row * (seatHeight + 10)) + (seatHeight / 2) - 90,
        child: IgnorePointer(
          child: SizedBox(
            width: 110,
            height: 110,
            child: Lottie.network(
              'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/Bird%20pair%20love%20and%20flying%20sky.json',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    });
  }
}
