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
      // 🟢 নতুন ভিডিও প্লেয়ারসহ ১০ সিটের জন্য সারি লজিক
      case 101:
        return (i ~/ 5 == j ~/ 5);
      case 12:
        if (i < 2 && j < 2) return true; // হোস্ট সিট (০ ও ১)
        if (i >= 2 && j >= 2) {
          int adjI = i - 2;
          int adjJ = j - 2;
          return (adjI ~/ 5 == adjJ ~/ 5) && ((adjI - adjJ).abs() == 1);
        }
        return false;
     case 18: // আপনার সুইচ কেস অনুযায়ী
        // যেহেতু এখন কোনো হোস্ট সিট নেই, তাই সব সিটই ৩টি সারিতে বিন্যস্ত (প্রতি সারিতে ৫টি করে)
        // প্রথম সারি: 0-4, দ্বিতীয় সারি: 5-9, তৃতীয় সারি: 10-14
        
        // ১. প্রথম সারি (index 0 থেকে 4) এর জন্য পাশাপাশি চেক
        if (i >= 0 && i < 5 && j >= 0 && j < 5) {
          return (i ~/ 5 == j ~/ 5) && ((i - j).abs() == 1);
        }
        
        // ২. দ্বিতীয় সারি (index 5 থেকে 9) এর জন্য পাশাপাশি চেক
        if (i >= 5 && i < 10 && j >= 5 && j < 10) {
          int adjI = i - 5;
          int adjJ = j - 5;
          return (adjI ~/ 5 == adjJ ~/ 5) && ((adjI - adjJ).abs() == 1);
        }
        
        // ৩. তৃতীয় সারি (index 10 থেকে 14) এর জন্য পাশাপাশি চেক
        if (i >= 10 && i < 15 && j >= 10 && j < 15) {
          int adjI = i - 10;
          int adjJ = j - 10;
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
        // ১. দুই (2) সিটের লেআউট (পুরাতন ১০০% ঠিক আছে)
        // ==========================================
        case 2:
          animationSize = 155.0;
          double colWidth = screenWidth / 2;
          int col = leftSeat % 2;
          leftPos = 50 + (col * colWidth) + (colWidth / 2) - (animationSize / 2) + (colWidth / 4); 
          topPos = 90;
          break;

        // ==========================================
        // ২. দশ (10) সিটের লেআউট (পুরাতন ১০০% ঠিক আছে)
        // ==========================================
        case 10:
          {
            double colWidth = screenWidth / 5;
            int row = leftSeat ~/ 5;
            int col = leftSeat % 5;
            leftPos = 16 + (col * colWidth) + (colWidth / 2);

            if (row == 0) {
              animationSize = 70.0;
              topPos = 5.0; 
            } else {
              animationSize = 70.0;
              topPos = 100.0; 
            }
          }
          break;

        // ==========================================
        // ৩. নতুন ভিডিও প্লেয়ার সহ ১০ সিট (플레이য়ারের নিচের ফাকা জায়গা হিসাব করে নিখুঁত পজিশন)
        // ==========================================
        case 101:
          {
            double colWidth = screenWidth / 5;
            int row = leftSeat ~/ 5;
            int col = leftSeat % 5;
            leftPos = 16 + (col * colWidth) + (colWidth / 2);

            if (row == 0) {
              // প্লেয়ার এবং সার্চবারের নিচের প্রথম সারি (০ থেকে ৪ নং সিট)
              animationSize = 70.0;
              topPos = 215.0; 
            } else {
              // প্লেয়ার এবং সার্চবারের নিচের দ্বিতীয় সারি (৫ থেকে ৯ নং সিট)
              animationSize = 70.0;
              topPos = 310.0; 
            }
          }
          break;

       // ==========================================
       // ৪. বারো (12) সিটের লেআউট (পুরাতন ১০০% ঠিক আছে)
       // ==========================================
        case 12:
          if (leftSeat < 2) {
            animationSize = 100.0;
            double colWidth = screenWidth / 2;
            leftPos = 65 + (leftSeat * colWidth) + (colWidth / 2) - (animationSize / 2) + (colWidth / 4); 
            topPos = 0.0;
          } else {
            int adj = leftSeat - 2;
            double colWidth = screenWidth / 5;
            int row = adj ~/ 5; 
            int col = adj % 5;

            if (row == 0) {
              animationSize = 70.0; 
              double leftOffset = 55.0; 
              topPos = 110.0;     
              leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
            } else {
              animationSize = 70.0; 
              double leftOffset = 55.0; 
              topPos = 200.0;     
              leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
            }
          }
          break;

       // ==========================================
        // ১৫ সিটের লেআউট (হোস্ট সিট ছাড়া, ৩ সারি × ৫ সিট)
        // ==========================================
        case 18: // আপনার কোডের সুইচ কেস অনুযায়ী এটি অপরিবর্তিত রাখা হলো
          if (leftSeat < 5) {
            // প্রথম সারি (index 0 থেকে 4)
            animationSize = 70.0;
            double colWidth = screenWidth / 5;
            int col = leftSeat % 5;
            leftPos = 20 + (col * colWidth) + (colWidth / 2); 
            topPos = 20.0; // প্রথম সারির top পজিশন 
          } else if (leftSeat < 10) {
            // দ্বিতীয় সারি (index 5 থেকে 9)
            animationSize = 70.0;
            int adj = leftSeat - 5;
            double colWidth = screenWidth / 5;
            int col = adj % 5;
            leftPos = 20 + (col * colWidth) + (colWidth / 2); 
            topPos = 110.0; // দ্বিতীয় সারির top পজিশন (প্রয়োজন অনুযায়ী বাড়াতে বা কমাতে পারেন)
          } else {
            // তৃতীয় সারি (index 10 থেকে 14)
            animationSize = 70.0;
            int adj = leftSeat - 10;
            double colWidth = screenWidth / 5;
            int col = adj % 5;
            leftPos = 20 + (col * colWidth) + (colWidth / 2);
            topPos = 200.0; // তৃতীয় সারির top পজিশন (প্রয়োজন অনুযায়ী বাড়াতে বা কমাতে পারেন)
          }
          break;

       // ==========================================
       // ৬. বিশ (20) সিটের লেআউট (পুরাতন ১০০% ঠিক আছে)
       // ==========================================
        case 20:
          double colWidth = screenWidth / 5;
          int row = leftSeat ~/ 5;
          int col = leftSeat % 5;

          if (row == 0) {
            animationSize = 70.0;        
            double leftOffset = 55.0;    
            topPos = 10.0;               
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else if (row == 1) {
            animationSize = 70.0;        
            double leftOffset = 55.0;    
            topPos = 100.0;              
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else if (row == 2) {
            animationSize = 70.0;        
            double leftOffset = 55.0;    
            topPos = 185.0;              
            leftPos = leftOffset + (col * colWidth) + (colWidth / 2) - (animationSize / 2);
          } else {
            animationSize = 70.0;        
            double leftOffset = 50.0;    
            topPos = 280.0;              
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