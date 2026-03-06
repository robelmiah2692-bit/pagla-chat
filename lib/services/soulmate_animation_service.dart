import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  // সিট পজিশন অনুযায়ী হার্ট দেখানোর লজিক
  static Widget buildHeartAnimation(int seatIndex1, int seatIndex2) {
    // পাশাপাশি সিট চেক (যেমন: ১-২, ৩-৪, ৫-৬)
    bool isAdjacent = (seatIndex1 - seatIndex2).abs() == 1;

    if (isAdjacent) {
      return Positioned(
        // দুই সিটের মাঝামাঝি পজিশন (আপনার সিটের ডিজাইন অনুযায়ী অ্যাডজাস্ট করে দেব)
        left: (seatIndex1 < seatIndex2) ? 40 : -40, 
        child: Lottie.network(
          'https://assets10.lottiefiles.com/packages/lf20_st966sjy.json', // জলমল করা হার্ট এনিমেশন
          width: 50,
          height: 50,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
