import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  late RtcEngine engine;
  
  // 🔥 আপনার দেওয়া নতুন অ্যাপ আইডি এখানে সেট করা হয়েছে
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // ১. পারমিশন লজিক: মোবাইলের জন্য আলাদা পারমিশন রিকোয়েস্ট
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

    // ৪. অডিও সেটিংস (ওয়েবে মাইক পারমিশন পপ-আপ ট্রিগার করার জন্য এটি জরুরি)
    await engine.enableAudio();
    
    // 🔥 এই লাইনটি ব্রাউজারকে সিগন্যাল দিবে মাইক এক্সেস করার জন্য
    await engine.enableLocalAudio(true); 

    // ৫. রোল সেটআপ: ব্রডকাস্টার হিসেবে সেট করা
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // ৬. অডিও কোয়ালিটি সেটিংস
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
    
    debugPrint("Agora Initialized with ID: $appId");
  }

  // ৭. রুমে জয়েন করা (সিটে ক্লিক করলে এটি কল হবে)
  Future<void> joinRoom(String channelName) async {
    await engine.joinChannel(
      token: "", // নতুন প্রজেক্ট Testing Mode এ থাকলে টোকেন লাগবে না
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true, // নিজের কথা পাঠানোর জন্য
        autoSubscribeAudio: true,    // অন্যের কথা শোনার জন্য
      ),
    );
    
    // ৮. স্পিকার লাউড করা (শুধু মোবাইলের জন্য)
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("Joined Voice Room: $channelName");
  }

  // মাইক অন/অফ করার ফাংশন
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  // রুম থেকে বের হওয়ার ফাংশন
  Future<void> leaveRoom() async {
    await engine.leaveChannel();
    debugPrint("Left Voice Room");
  }
}
