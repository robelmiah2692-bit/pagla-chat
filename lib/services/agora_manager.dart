import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  late RtcEngine engine;
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // ১. পারমিশন লজিক: ব্রাউজারে এরর এড়াতে kIsWeb চেক ঠিক আছে
    if (!kIsWeb) {
      await [Permission.microphone].request();
    }

    // ২. ইঞ্জিন তৈরি
    engine = createAgoraRtcEngine();
    
    // ৩. ইনিশিয়ালাইজেশন
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ৪. অডিও প্রোফাইল এবং রোল সেটআপ (কথা শোনার ও বলার জন্য এটি জরুরি)
    await engine.enableAudio();
    
    // 🔥 এই লাইনটি যোগ করা হয়েছে যাতে কথা আদান-প্রদান ঠিক থাকে
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
    
    debugPrint("Agora Initialized with ID: $appId");
  }

  // ৫. রুমে জয়েন করা
  Future<void> joinRoom(String channelName) async {
    await engine.joinChannel(
      token: "", 
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster, // কথা বলার রোল
        publishMicrophoneTrack: true, // নিজের মাইক পাঠানো
        autoSubscribeAudio: true, // অন্যের কথা শোনা
      ),
    );
    
    // 🔥 স্পিকার লাউড করা (মোবাইলের জন্য)
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("Joined Voice Room: $channelName");
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  Future<void> leaveRoom() async {
    await engine.leaveChannel();
    debugPrint("Left Voice Room");
  }
}
