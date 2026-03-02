import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; // kIsWeb চেক করার জন্য
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  late RtcEngine engine;
  
  // আপনার দেওয়া এগোরা অ্যাপ আইডি
  final String appId = "bd010dec4aa141228c87ec2cb9d4f6e8"; 

  Future<void> initAgora() async {
    // ১. পারমিশন লজিক: ব্রাউজারে (Web) permission_handler এরর দেয়, তাই চেক করা হয়েছে
    if (!kIsWeb) {
      await [Permission.microphone].request();
    }

    // ২. ইঞ্জিন তৈরি
    engine = createAgoraRtcEngine();
    
    // ৩. ইনিশিয়ালাইজেশন
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ৪. অডিও প্রোফাইল সেটআপ (আপনার হাই কোয়ালিটি সেটিংস)
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
    
    debugPrint("Agora Initialized with ID: $appId");
  }

  // ৫. সিটে ক্লিক করে বসার পরেই এই ফাংশনটি কল হবে (আপনার নির্দেশ অনুযায়ী)
  Future<void> joinRoom(String channelName) async {
    await engine.joinChannel(
      token: "", // আপনার টোকেন থাকলে এখানে বসবে
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
    debugPrint("Joined Voice Room: $channelName");
  }

  // মাইক অন/অফ করা
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  // সিট থেকে উঠে গেলে বা লিভ নিলে
  Future<void> leaveRoom() async {
    await engine.leaveChannel();
    debugPrint("Left Voice Room");
  }
}
