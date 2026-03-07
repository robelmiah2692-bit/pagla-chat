import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceEngine {
  late RtcEngine _engine;

  Future<void> initAgora(String appId) async {
    // ১. মাইক পারমিশন নেওয়া
    await [Permission.microphone].request();

    // ২. ইঞ্জিন তৈরি করা
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    // ৩. ইভেন্ট লিসেনার
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("রুম জয়েন হয়েছে successfully!");
        },
      ),
    );

    // ৪. অডিও প্রোফাইল সেটআপ
    await _engine.enableAudio();
    
    // 🔥 এখানে পরিবর্তন করা হয়েছে: Named arguments ব্যবহার করা হয়েছে
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    
    // ✅ এই লাইনটিই আপনার GitHub Build ফেইল করাচ্ছিল, এখন ঠিক করে দেওয়া হয়েছে:
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
  }

  // রুমে ঢোকার ফাংশন
  Future<void> joinRoom(String token, String channelId, int uid) async {
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
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
    // রিলিজ করার আগে চেক করে নেওয়া ভালো
    // await _engine.release(); 
  }
}
