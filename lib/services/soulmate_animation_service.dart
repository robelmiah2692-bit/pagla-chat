import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SoulmateAnimationService {
  // 🎯 মেইন উইজেট: যা আপনার ৫ কলামের সিটের ঠিক মাঝখানে হার্ট বসিয়ে দেবে
  static Widget buildSoulmateHeartOverlay({
    required List<dynamic> seats, // রুমের সব সিটের লাইভ লিস্ট (১৫টি সিট)
    required String
        myPartnerAuthUID, // ফায়ারস্টোর প্রোফাইল থেকে আসা সোলমেট আইডি
    required String myCurrentAuthUID, // ইউজারের নিজের লম্বা 'authUID'
  }) {
    if (seats.isEmpty || myPartnerAuthUID.isEmpty)
      return const SizedBox.shrink();

    int mySeatIndex = -1;
    int partnerSeatIndex = -1;

    // ১. সিট লিস্ট লুপ করে শুধুমাত্র ৬ ডিজিটের 'uID' মিলিয়ে ইনডেক্স বের করা
    for (int i = 0; i < seats.length; i++) {
      var seat = seats[i];
      if (seat == null) continue;

      // ৬ ডিজিটের আইডি বের করা (রুমের সিট থেকে আসা uID)
      String? seatUID = seat["uID"]?.toString();

      // নিজের আইডি চেক (শুধু ৬ ডিজিটের uID)
      if (seatUID != null && seatUID == myCurrentAuthUID) {
        mySeatIndex = i;
      }

      // পার্টনারের আইডি চেক (শুধু ৬ ডিজিটের uID)
      if (seatUID != null && seatUID == myPartnerAuthUID) {
        partnerSeatIndex = i;
      }
    }

    // ২. দুজনেই সিটে না বসলে রিটার্ন করবে
    if (mySeatIndex == -1 || partnerSeatIndex == -1) {
      return const SizedBox.shrink();
    }

    // ৩. পাশাপাশি সিট চেক
    bool isAdjacent = (mySeatIndex - partnerSeatIndex).abs() == 1;

    // একই লাইনে আছে কিনা তা নিশ্চিত করা
    int myRow = mySeatIndex ~/ 5;
    int partnerRow = partnerSeatIndex ~/ 5;
    bool isSameRow = myRow == partnerRow;

    if (isAdjacent && isSameRow) {
      // বামের সিট কোনটি সেটি ট্র্যাক করা
      int leftSeat =
          (mySeatIndex < partnerSeatIndex) ? mySeatIndex : partnerSeatIndex;

      int row = leftSeat ~/ 5;
      int col = leftSeat % 5;

      return Builder(
        builder: (context) {
          double totalWidth = MediaQuery.of(context).size.width;

          // আপনার মেইন গ্রিডভিউয়ের দুই পাশের মার্জিন (ডিফল্ট ১৬ করে দুপাশে ৩২ বাদ)
          double gridWidth = totalWidth - 32;
          double colWidth = gridWidth / 5; // প্রতি সিটের আসল উইডথ

          // 📐 ৫ কলামের গ্রিডের মেইন হাইট ক্যালকুলেশন
          double seatHeight = colWidth / 0.75;

          // 📐 সাইজ ৮০ অনুযায়ী দুই সিটের ঠিক মাঝখানের এক্সাক্ট পজিশন (colWidth - ৪০)
          double leftPosition = 16 + (col * colWidth) + (colWidth - 40);

          // 🔥 ফিক্স: হার্টটিকে সাইজে বড় করে সিটের সামান্য ওপরে ভাসিয়ে রাখার পারফেক্ট টপ পজিশন
          double topPosition =
              (row * (seatHeight + 10)) + (seatHeight / 2) - 45;

          return Positioned(
            left: leftPosition,
            top: topPosition,
            child: IgnorePointer(
              child: SizedBox(
                width:
                    80, // 🔥 ফিক্স: বাইরের কন্টেইনার সাইজ ৮০ করা হলো যেন লটি বড় হতে পারে
                height:
                    80, // 🔥 ফিক্স: বাইরের কন্টেইনার সাইজ ৮০ করা হলো যেন লটি বড় হতে পারে
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ✨ জলমল করা লটি এনিমেশন (১০০% বড় সাইজে রেন্ডার হবে)
                    Lottie.network(
                      'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/heart%20beat.json',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
