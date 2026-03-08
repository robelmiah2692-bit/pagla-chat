import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 

class AgoraManager {
  late RtcEngine engine;
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // ১. আপনার তৈরি করা সেই মাইক পারমিশন লজিক (অপরিবর্তিত)
    if (kIsWeb) {
      try {
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
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ৪. অডিও ইঞ্জিন চালু করা
    await engine.enableAudio();
    
    // ৫. রোল সেট করা
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // 🔥 ৬. সাউন্ড সচল করতে এটি গুরুত্বপূর্ণ
    await engine.muteLocalAudioStream(false);
    
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    debugPrint("Agora Initialized: $appId");
  }

  // ৭. রুমে জয়েন করা (ভয়েস শোনার জন্য এখানে ছোট পরিবর্তন)
  Future<void> joinRoom(String channelName) async {
    // 🔥 ফিক্স: ওয়েবে uid: 0 দিলে অনেক সময় ভয়েস অন্যদের কাছে যায় না। 
    // তাই একটি ইউনিক আইডি (যেমন: ১২৩) ব্যবহার করছি।
    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName,
      uid: myUid, // এখানে ০ এর বদলে ইউনিক আইডি দেওয়া হয়েছে
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true, // ভয়েস পাঠানোর জন্য
        autoSubscribeAudio: true,     // ভয়েস শোনার জন্য
      ),
    );
    
    // 🔥 জয়েন করার পর ভলিউম এবং মিউট স্ট্যাটাস রিফ্রেশ
    await engine.adjustRecordingSignalVolume(100); 
    await engine.muteLocalAudioStream(false);
    
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("Joined Voice Room: $channelName with UID: $myUid");
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
