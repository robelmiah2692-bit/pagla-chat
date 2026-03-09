import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceEngine {
  late RtcEngine _engine;

  RtcEngine get engine => _engine; 

  Future<void> initAgora(String appId) async {
    // ১. পারমিশন
    await [Permission.microphone].request();

    // ২. ইঞ্জিন তৈরি
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ৩. ইভেন্ট লিসেনার
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("Joined successfully!");
        },
      ),
    );

    // ৪. অডিও প্রোফাইল
    await _engine.enableAudio();
    
    // 🔥 ৫. এখানে লিসেনার/অডিয়েন্স সেট করুন (যাতে রুমে ঢোকার সময় গ্রিন ডট না আসে)
    await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
  }

  // রুমে ঢোকার ফাংশন
  Future<void> joinRoom(String channelId) async {
    await _engine.joinChannel(
      token: "", 
      channelId: channelId,
      uid: 0, 
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: false, // 🔥 শুরুতে মাইক বন্ধ
        autoSubscribeAudio: true,
        clientRoleType: ClientRoleType.clientRoleAudience, // 🔥 অডিয়েন্স হিসেবে জয়েন
      ),
    );
  }

  // মাইক অন-অফ
  Future<void> toggleMic(bool mute) async {
    await _engine.muteLocalAudioStream(mute);
    if (!mute) {
      await _engine.enableLocalAudio(true);
    }
  }

  Future<void> leaveRoom() async {
    await _engine.leaveChannel();
  }
}
