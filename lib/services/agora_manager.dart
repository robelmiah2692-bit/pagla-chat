import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; // এটি বাদ দিলে ইঞ্জিন ডাবল লোড হয়ে মাইক কেটে যেতে পারে
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // যদি অলরেডি ইনিশিয়ালাইজ হয়ে থাকে, তবে আর করার দরকার নেই
    if (_isInitialized) return;

    // ১. আপনার তৈরি করা সেই মাইক পারমিশন লজিক (অপরিবর্তিত)
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
        debugPrint("Web Browser Microphone Requesting...");
      } catch (e) {
        debugPrint("Microphone Permission Denied: $e");
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

    // ৬. সাউন্ড সচল করা
    await engine.muteLocalAudioStream(false);
    
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    _isInitialized = true; // মার্ক করে রাখলাম যে ইঞ্জিন রেডি
    debugPrint("Agora Initialized: $appId");
  }

  // ৭. রুমে জয়েন করা
  Future<void> joinRoom(String channelName) async {
    // ফিক্স: ইউনিক আইডি ব্যবহার করছি যাতে অডিও পাবলিশ হয়
    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName,
      uid: myUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true, 
        autoSubscribeAudio: true,     
      ),
    );
    
    // জয়েন করার পর সাউন্ড নিশ্চিত করা
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
