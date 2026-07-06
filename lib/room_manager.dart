import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:pagla_chat/services/floating_bubble_service.dart';

class RoomManager {
  static final RoomManager _instance = RoomManager._internal();
  factory RoomManager() => _instance;
  RoomManager._internal();

  // গ্লোবাল ভেরিয়েবল যা পপ করলেও মুছবে না
  String? activeRoomId;
  int currentSeatIndex = -1;
  RtcEngine? engine;
  bool isMinimized = false;

  // নতুন ক্লিনআপ লজিক হোল্ডার
  VoidCallback? onForceExit;

  // পুরাতন রুম থেকে এক্সিট করার লজিক
  void forceExitOldRoom() {
    if (activeRoomId != null) {
      debugPrint("Force exiting old room: $activeRoomId");
      
      // ১. যদি কোনো ক্লিনআপ ফাংশন সেট করা থাকে, তবে সেটি রান করো
      if (onForceExit != null) {
        onForceExit!();
      }

      // ২. বাবল হাইড করো
      FloatingBubbleService.hide();
      
      // ৩. রিসেট করা
      activeRoomId = null;
      currentSeatIndex = -1;
      onForceExit = null;
      isMinimized = false;
      engine = null;
    }
  }

  void reset() {
    activeRoomId = null;
    currentSeatIndex = -1;
    isMinimized = false;
    engine = null;
    onForceExit = null; // রিসেট করার সময় ক্লিনআপ লজিকও মুছে দেওয়া ভালো
  }
}