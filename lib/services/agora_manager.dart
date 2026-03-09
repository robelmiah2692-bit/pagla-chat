import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    // যদি অলরেডি ইনিশিয়ালাইজ হয়ে থাকে, তবে আর করার দরকার নেই
    if (_isInitialized) return;

    // ১. আপনার সেই মাইক পারমিশন লজিক
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
    
    // ৫. রোল শুরুতে অডিয়েন্স রাখা ভালো (সিটে বসলে ব্রডকাস্টার হবে)
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);

    // ৬. সাউন্ড প্রোফাইল সেটআপ
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

  // ৭. রুমে জয়েন করা (সিটে বসার সময় কল হবে)
  Future<void> joinRoom(String channelName) async {
    if (!_isInitialized) await initAgora();

    // প্রত্যেক ইউজারের জন্য আলাদা আইডি (যাতে কথা না কাটে)
    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: myUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster, // কথা বলার রোল
        publishMicrophoneTrack: true, // মাইক সচল করা
        autoSubscribeAudio: true,     // অন্যদের কথা শোনা
      ),
    );
    
    // 🔥 ওয়েব ব্রাউজারের জন্য এই ২টা লাইন মাস্ট, না হলে গ্রিন ডট আসবে না
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100); 
    
    if (!kIsWeb) {
      await engine.setEnableSpeakerphone(true);
    }
    
    debugPrint("✅ সিটে বসা সফল! এখন গ্রিন মাইক আসবে। UID: $myUid");
  }

  // মাইক অন/অফ
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  // রুম থেকে বের হওয়া (সিট ছাড়লে এটি কল হবে)
  Future<void> leaveRoom() async {
    try {
      await engine.leaveChannel();
      debugPrint("Left Voice Room");
    } catch (e) {
      debugPrint("Error leaving room: $e");
    }
  }
}
