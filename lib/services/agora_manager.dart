import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; // 🔥 ওয়েবে পারমিশনের জন্য এটি লাগবে

class AgoraManager {
  late RtcEngine engine;
  
  // 🔥 আপনার দেওয়া অ্যাপ আইডি
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // ১. পারমিশন লজিক
    if (kIsWeb) {
      try {
        // 🔥 ফিক্স: ওয়েবে ব্রাউজারকে বাধ্য করা মাইক পারমিশন পপ-আপ দেখানোর জন্য
        await html.window.navigator.getUserMedia(audio: true);
        debugPrint("Web Browser Microphone Requesting...");
      } catch (e) {
        debugPrint("Microphone Permission Denied or Error: $e");
      }
    } else {
      await [Permission.microphone].request();
    }

    // ২. ইঞ্জিন তৈরি
    engine = createAgoraRtcEngine();
    
    // ৩. ইনিশিয়ালাইজেশন
    await engine.initialize(RtcEngineContext(
      appId: appId,
      // 🔥 ফিক্স: মাল্টি-ইউজার চ্যাটরুমের জন্য LiveBroadcasting সবথেকে ভালো
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ৪. অডিও ইঞ্জিন চালু করা
    await engine.enableAudio();
    
    // ৫. ডিফল্ট রোল সেট করা (Broadcaster না হলে কথা যাবে না)
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // 🔥 ৬. ওয়েবে অডিও স্ট্রীম সচল করার জন্য এটি মাস্ট
    await engine.muteLocalAudioStream(false);
    
    // অডিও কোয়ালিটি সেটআপ
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    debugPrint("Agora Initialized for Web/Mobile: $appId");
  }

  // ৭. রুমে জয়েন করা
  Future<void> joinRoom(String channelName) async {
    await engine.joinChannel(
      token: "", 
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true, // নিজের কথা পাঠানোর জন্য
        autoSubscribeAudio: true,     // অন্যের কথা শোনার জন্য
      ),
    );
    
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("Joined Voice Room: $channelName");
  }

  // মাইক অন/অফ (isMute: true মানে কথা বন্ধ, false মানে কথা চালু)
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  // রুম থেকে বের হওয়া
  Future<void> leaveRoom() async {
    await engine.leaveChannel();
    debugPrint("Left Voice Room");
  }
}
