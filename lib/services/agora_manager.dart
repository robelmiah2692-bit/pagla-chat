import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  late RtcEngine engine;
  
  // 🔥 আপনার দেওয়া অ্যাপ আইডি
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // ১. পারমিশন লজিক
    if (kIsWeb) {
      // ওয়েবে ব্রাউজার যখনই মাইক এক্সেস চাবে, এইটা সাহায্য করবে
      debugPrint("Web Browser Microphone Requesting...");
    } else {
      await [Permission.microphone].request();
    }

    // ২. ইঞ্জিন তৈরি
    engine = createAgoraRtcEngine();
    
    // ৩. ইনিশিয়ালাইজেশন
    await engine.initialize(RtcEngineContext(
      appId: appId,
      // ওয়েব এবং অডিও কলের জন্য Communication প্রোফাইল সবথেকে ভালো কাজ করে
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // ৪. অডিও ইঞ্জিন চালু করা
    await engine.enableAudio();
    
    // 🔥 ৫. ওয়েবে মাইক পারমিশন পপ-আপ না আসলে সাউন্ড কানেক্ট হবে না
    // এই কমান্ডটি ব্রাউজারকে বাধ্য করবে পারমিশন ডায়ালগ দেখাতে
    await engine.enableLocalAudio(true); 

    // ৬. অডিও কোয়ালিটি এবং চ্যাটরুম সিনারিও সেট করা
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    debugPrint("Agora Initialized for Web/Mobile: $appId");
  }

  // ৭. রুমে জয়েন করা
  Future<void> joinRoom(String channelName) async {
    // জয়েন করার ঠিক আগে আবার চেক করা যেন পারমিশন মিস না হয়
    await engine.joinChannel(
      token: "", 
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true, // নিজের কথা পাঠানোর জন্য
        autoSubscribeAudio: true,    // অন্যের কথা শোনার জন্য
      ),
    );
    
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("Joined Voice Room: $channelName");
  }

  // মাইক অন/অফ
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  // রুম থেকে বের হওয়া
  Future<void> leaveRoom() async {
    await engine.leaveChannel();
    debugPrint("Left Voice Room");
  }
}
