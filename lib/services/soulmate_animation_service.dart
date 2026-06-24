import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  
  // 🎯 মেইন উইজেট: সব সোলমেট পার্টনারের জন্য হার্ট এনিমেশন রেন্ডার করবে
  static Widget buildSoulmateHeartOverlay({
    required List<dynamic> seats,
    required List<dynamic> mySoulmatesList,
    required String myCurrentAuthUID,
  }) {
    if (seats.isEmpty || mySoulmatesList.isEmpty) return const SizedBox.shrink();

    int mySeatIndex = -1;
    List<int> partnerSeatIndices = [];

    // ১. সিট লিস্ট থেকে নিজের এবং পার্টনারদের ইনডেক্স খুঁজে বের করা
    for (int i = 0; i < seats.length; i++) {
      var seat = seats[i];
      if (seat == null) continue;
      
      String? seatUID = seat["uID"]?.toString();
      if (seatUID == null) continue;

      if (seatUID == myCurrentAuthUID) {
        mySeatIndex = i;
      }
      
      // যদি সিটে বসা ইউজার আপনার সোলমেট লিস্টে থাকে
      if (mySoulmatesList.contains(seatUID)) {
        partnerSeatIndices.add(i);
      }
    }

    if (mySeatIndex == -1 || partnerSeatIndices.isEmpty) {
      return const SizedBox.shrink();
    }

    // ২. পাশাপাশি বসে থাকা পার্টনারদের জন্য হার্ট লিস্ট তৈরি করা
    List<Widget> hearts = [];
    for (int pIndex in partnerSeatIndices) {
      // পাশাপাশি সিট এবং একই লাইনে আছে কিনা চেক করা
      if ((mySeatIndex - pIndex).abs() == 1 && (mySeatIndex ~/ 5 == pIndex ~/ 5)) {
        hearts.add(_createHeartWidget(mySeatIndex, pIndex));
      }
    }

    return Stack(children: hearts);
  }

  // ৩. হার্ট উইজেট তৈরির আলাদা মেথড
  static Widget _createHeartWidget(int mySeatIndex, int pIndex) {
    int leftSeat = (mySeatIndex < pIndex) ? mySeatIndex : pIndex;
    int row = leftSeat ~/ 5;
    int col = leftSeat % 5;

    return Builder(builder: (context) {
      double totalWidth = MediaQuery.of(context).size.width - 32;
      double colWidth = totalWidth / 5;
      double seatHeight = colWidth / 0.75;
      
      double leftPosition = 16 + (col * colWidth) + (colWidth - 40);
      double topPosition = (row * (seatHeight + 10)) + (seatHeight / 2) - 45;

      return Positioned(
        left: leftPosition,
        top: topPosition,
        child: IgnorePointer(
          child: SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/Bird%20pair%20love%20and%20flying%20sky.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
    });
  }
}