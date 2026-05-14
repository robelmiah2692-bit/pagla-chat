import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RoomManager {
  static final RoomManager _instance = RoomManager._internal();
  factory RoomManager() => _instance;
  RoomManager._internal();

  // গ্লোবাল ভেরিয়েবল যা পপ করলেও মুছবে না
  String? activeRoomId;
  int currentSeatIndex = -1;
  RtcEngine? engine;
  bool isMinimized = false;

  void reset() {
    activeRoomId = null;
    currentSeatIndex = -1;
    isMinimized = false;
    engine = null;
  }
}