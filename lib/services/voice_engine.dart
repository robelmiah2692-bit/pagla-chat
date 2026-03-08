import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceEngine {
  late RtcEngine _engine;

  // 🔥 এই লাইনটি অবশ্যই যোগ করুন, নাহলে voice_room.dart এরর দেবে
  RtcEngine get engine => _engine; 

  Future<void> initAgora(String appId) async {
    // ১. মাইক পারমিশন নেওয়া
    await [Permission.microphone].request();

    // ২. ইঞ্জিন তৈরি করা
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    // ৩. ইভেন্ট লিসেনার
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("রুম জয়েন হয়েছে successfully!");
        },
      ),
    );

    // ৪. অডিও প্রোফাইল সেটআপ
    await _engine.enableAudio();
    
    // ৫. চ্যানেল প্রোফাইল সেট করা
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    
    // ৬. ক্লায়েন্ট রোল সেট করা
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  // রুমে ঢোকার ফাংশন
  Future<void> joinRoom(String channelId) async {
    await _engine.joinChannel(
      token: "", // আপনার যদি টোকেন না থাকে তবে খালি রাখুন
      channelId: channelId,
      uid: 0, // ০ দিলে এগোরা অটোমেটিক একটা আইডি নেবে
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  // মাইক অন-অফ করার ফাংশন
  Future<void> toggleMic(bool mute) async {
    await _engine.muteLocalAudioStream(mute);
  }

  Future<void> leaveRoom() async {
    await _engine.leaveChannel();
  }
}
