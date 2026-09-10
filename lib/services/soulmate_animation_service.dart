import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  static Widget buildSoulmateHeartOverlay({
    required List<dynamic> seats,
    required Map<String, List<dynamic>> allUsersSoulmates,
    required int layoutItemCount, 
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

        if (_areSeatsAdjacent(i, j, layoutItemCount)) {
          if (soulmatesA.contains(uidB)) {
            String pairId = (i < j) ? "$i-$j" : "$j-$i";
            if (!processedPairs.contains(pairId)) {
              hearts.add(_createDynamicHeartWidget(i, j, layoutItemCount));
              processedPairs.add(pairId);
            }
          }
        }
      }
    }
    return RepaintBoundary(child: Stack(children: hearts));
  }

  static bool _areSeatsAdjacent(int i, int j, int layoutCount) {
    if ((i - j).abs() != 1) {
      if (layoutCount == 12 && ((i == 0 && j == 1) || (i == 1 && j == 0))) return true;
      if (layoutCount == 18 && ((i == 0 && j == 1) || (i == 1 && j == 2) || ((i - j).abs() == 1 && i < 3 && j < 3))) {
        return (i < 3 && j < 3 && (i - j).abs() == 1);
      }
      return false;
    }

    switch (layoutCount) {
      case 2:
        return (i < 2 && j < 2);
      case 10:
      case 20:
        return (i ~/ 5 == j ~/ 5);
      case 12:
        if (i < 2 && j < 2) return true; // হোস্ট সিট (০ ও ১)
        if (i >= 2 && j >= 2) {
          int adjI = i - 2;
          int adjJ = j - 2;
          return (adjI ~/ 5 == adjJ ~/ 5) && ((adjI - adjJ).abs() == 1);
        }
        return false;
      case 18:
        if (i < 3 && j < 3) return (i - j).abs() == 1; // হোস্ট সিটগুলোর (০, ১, ২) জন্য পাশাপাশি চেক
        
        if (i >= 3 && i < 8 && j >= 3 && j < 8) {
          int adjI = i - 3;
          int adjJ = j - 3;
          return (adjI ~/ 5 == adjJ ~/ 5) && ((adjI - adjJ).abs() == 1);
        }
        
        if (i >= 8 && j >= 8) {
          int adjI = i - 8;
          int adjJ = j - 8;
          return (adjI ~/ 5 == adjJ ~/ 5) && ((adjI - adjJ).abs() == 1);
        }
        return false;
      default:
        return (i ~/ 4 == j ~/ 4);
    }
  }

  static Widget _createDynamicHeartWidget(int index1, int index2, int layoutCount) {
    int leftSeat = (index1 < index2) ? index1 : index2;

    return Builder(builder: (context) {
      double screenWidth = MediaQuery.of(context).size.width - 32;
      double leftPos = 0;
      double topPos = 0;
      double animationSize = 60.0;

      switch (layoutCount) {
        // ==========================================
        // ১. দুই (2) সিটের লেআউট
        // ==========================================
        case 2:
          animationSize = 155.0; // অ্যানিমেশনের সাইজ
          double colWidth = screenWidth / 2;
          int col = leftSeat % 2;
          leftPos = 50 + (col * colWidth) + (colWidth / 2) - (animationSize / 2) + (colWidth / 4); 
          topPos = 90; // উপর-নিচ পজিশন
          break;

        // ==========================================
        // ২. দশ (10) সিটের লেআউট (২ সারি: প্রতি সারিতে ৫টি করে)
        // ==========================================
        case 10:
          double colWidth = screenWidth / 5;
          int row = leftSeat ~/ 5;
          int col = leftSeat % 5;
          leftPos = 16 + (col * colWidth) + (colWidth / 2);

          if (row == 0) {
            // 🟢 ১০ সিটের প্রথম সারি (উপরে)
            animationSize = 70.0; // প্রথম সারির সাইজ
            topPos = 5.0;        // প্রথম সারির উপর-নিচ পজিশন
          } else {
            // 🟢 ১০ সিটের দ্বিতীয় সারি (নিচে)
            animationSize = 70.0; // দ্বিতীয় সারির সাইজ
            topPos = 100.0;       // দ্বিতীয় সারির উপর-নিচ পজিশন
          }
          break;

       // ==========================================
        // ৩. বারো (12) সিটের লেআউট (হোস্ট + নিচের সারি)
        // ==========================================
        case 12:
          if (leftSeat < 2) {
            // 🟢 ১২ সিটের হোস্ট সারি (০ ও ১ নম্বর সিট)
            animationSize = 135.0; // হোস্ট সারির সাইজ
            double colWidth = screenWidth / 2;
            leftPos = 65 + (leftSeat * colWidth) + (colWidth / 2) - (animationSize / 2) + (colWidth / 4); 
            topPos = 0.0;        // হোস্ট সারির উপর-নিচ পজিশন
          } else {
            // নিচের সিটগুলো (২ থেকে ১১)
            int adj = leftSeat - 2;
            double colWidth = screenWidth / 5;
            int row = adj ~/ 5; // row 0 মানে প্রথম সারি (সিট ২ থেকে ৬), row 1 মানে দ্বিতীয় সারি (সিট ৭ থেকে ১১)
            int col = adj % 5;

            if (row == 0) {
              // 🟢 ১২ সিটের নিচের প্রথম সারি (সিট ২, ৩, ৪, ৫, ৬)
              animationSize = 70.0; // প্রথম সারির সাইজ
              double leftOffset = 45.0; // 🟢 ডানে-বামে সরানোর জন্য মান পরিবর্তন করুন
              topPos = 140.0;       // প্রথম সারির উপর-নিচ পজিশন
              leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
            } else {
              // 🟢 ১২ সিটের নিচের দ্বিতীয় সারি (সিট ৭, ৮, ৯, ১০, ১১)
              animationSize = 70.0; // দ্বিতীয় সারির সাইজ
              double leftOffset = 45.0; // 🟢 ডানে-বামে সরানোর জন্য মান পরিবর্তন করুন
              topPos = 235.0;       // দ্বিতীয় সারির উপর-নিচ পজিশন
              leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
            }
          }
          break;

        // ==========================================
        // ৪. আঠারো (18) সিটের লেআউট (হোস্ট + মিডল + নিচের সারি)
        // ==========================================
        case 18:
          if (leftSeat < 3) {
            // 🟢 ১৮ সিটের হোস্ট সারি (০, ১, ২ নম্বর সিট)
            animationSize = 90.0; // হোস্ট সারির সাইজ
            double colWidth = screenWidth / 3;
            leftPos = 60 + (leftSeat * colWidth) + (colWidth / 2) - 25; 
            topPos = 8.0;        // হোস্ট সারির উপর-নিচ পজিশন
          } else if (leftSeat < 8) {
            // 🟢 ১৮ সিটের মাঝের সারি (৩ থেকে ৭ নম্বর সিট)
            animationSize = 70.0; // মাঝের সারির সাইজ
            int adj = leftSeat - 3;
            double colWidth = screenWidth / 5;
            int col = adj % 5;
            leftPos = 20 + (col * colWidth) + (colWidth / 2); 
            topPos = 120.0;       // মাঝের সারির উপর-নিচ পজিশন
          } else {
            // 🟢 ১৮ সিটের নিচের সারিগুলো (৮ থেকে ১৭ নম্বর সিট)
            int adj = leftSeat - 8;
            double colWidth = screenWidth / 5;
            int row = adj ~/ 5;
            int col = adj % 5;
            leftPos = 20 + (col * colWidth) + (colWidth / 2);

            if (row == 0) {
              // ১৮ সিটের নিচের প্রথম সারি
              animationSize = 70.0;
              topPos = 210.0;
            } else {
              // ১৮ সিটের নিচের দ্বিতীয় সারি
              animationSize = 70.0;
              topPos = 295.0;
            }
          }
          break;

       // ==========================================
        // ৫. বিশ (20) সিটের লেআউট (৪টি আলাদা সারি)
        // ==========================================
        case 20:
          double colWidth = screenWidth / 5;
          int row = leftSeat ~/ 5;
          int col = leftSeat % 5;

          if (row == 0) {
            // 🟢 ২০ সিটের ১ম সারি (একেবারে উপরের সারি)
            animationSize = 70.0;         // ১ম সারির অ্যানিমেশন সাইজ
            double leftOffset = 55.0;     // 🟢 ১ম সারির ডানে-বামে পজিশন
            topPos = 10.0;                // 🟢 ১ম সারির উপর-নিচ পজিশন
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else if (row == 1) {
            // 🟢 ২০ সিটের ২য় সারি
            animationSize = 70.0;         // ২য় সারির অ্যানিমেশন সাইজ
            double leftOffset = 55.0;     // 🟢 ২য় সারির ডানে-বামে পজিশন
            topPos = 100.0;               // 🟢 ২য় সারির উপর-নিচ পজিশন
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else if (row == 2) {
            // 🟢 ২০ সিটের ৩য় সারি
            animationSize = 70.0;         // ৩য় সারির অ্যানিমেশন সাইজ
            double leftOffset = 55.0;     // 🟢 ৩য় সারির ডানে-বামে পজিশন
            topPos = 185.0;               // 🟢 ৩য় সারির উপর-নিচ পজিশন
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else {
            // 🟢 ২০ সিটের ৪র্থ সারি (একেবারে নিচের সারি)
            animationSize = 70.0;         // ৪র্থ সারির অ্যানিমেশন সাইজ
            double leftOffset = 50.0;     // 🟢 ৪র্থ সারির ডানে-বামে পজিশন
            topPos = 280.0;               // 🟢 ৪র্থ সারির উপর-নিচ পজিশন
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          }
          break;

        default:
          animationSize = 70.0;
          break;
      }

      return Positioned(
        left: leftPos, 
        top: topPos,   
        child: IgnorePointer(
          child: SizedBox(
            width: animationSize,  
            height: animationSize, 
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