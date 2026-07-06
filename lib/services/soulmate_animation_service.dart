import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  
  static Widget buildSoulmateHeartOverlay({
    required List<dynamic> seats,
    required Map<String, List<dynamic>> allUsersSoulmates, // { "978051": ["519857", "346306", ...] }
  }) {
    List<Widget> hearts = [];
    Set<String> processedPairs = {};

    for (int i = 0; i < seats.length; i++) {
      var seatA = seats[i];
      if (seatA == null || seatA['uID'] == null) continue;
      String uidA = seatA['uID'].toString(); 

      // ইউজার A এর সোলমেট লিস্ট পাওয়া যাচ্ছে সরাসরি ডকুমেন্ট আইডি (uidA) দিয়ে
      List<dynamic> soulmatesA = allUsersSoulmates[uidA] ?? [];

      for (int j = 0; j < seats.length; j++) {
        var seatB = seats[j];
        if (seatB == null || seatB['uID'] == null) continue;
        String uidB = seatB['uID'].toString();

        // ১. পাশাপাশি বসা এবং একই সারিতে আছে কিনা চেক
        if ((i - j).abs() == 1 && (i ~/ 5 == j ~/ 5)) {
          // ২. ইউজার A এর সোলমেট লিস্টে ইউজার B আছে কিনা চেক
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
    return Stack(children: hearts);
  }

  static Widget _createHeartWidget(int index1, int index2) {
    int leftSeat = (index1 < index2) ? index1 : index2;
    int row = leftSeat ~/ 5;
    int col = leftSeat % 5;

    return Builder(builder: (context) {
      double totalWidth = MediaQuery.of(context).size.width - 32;
      double colWidth = totalWidth / 5;
      double seatHeight = colWidth / 0.75;
      
      return Positioned(
        left: 16 + (col * colWidth) + (colWidth - 40),
        top: (row * (seatHeight + 10)) + (seatHeight / 2) - 45,
        child: IgnorePointer(
          child: SizedBox(
            width: 80, height: 80,
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