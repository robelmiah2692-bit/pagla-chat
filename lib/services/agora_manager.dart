import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 

  Future<void> initAgora() async {
    if (_isInitialized) return;

    // ১. পারমিশন লজিক পরিবর্তন (Web-এর জন্য এখানে getUserMedia করার দরকার নেই শুরুতে)
    if (!kIsWeb) {
      await [Permission.microphone].request();
    }

    engine = createAgoraRtcEngine();
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ২. অডিও ইঞ্জিন এনাবল করলেও শুরুতে অডিও ট্র্যাক বন্ধ রাখা
    await engine.enableAudio();
    
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

  // ১. রুমে জয়েন করা (সবুজ আইকন আসবে না)
  Future<void> joinAsListener(String channelName) async {
    if (!_isInitialized) await initAgora();

    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: myUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience, // লিসেনার
        publishMicrophoneTrack: false, // 🔥 মাইক ট্র্যাক পাঠানো পুরোপুরি বন্ধ
        autoSubscribeAudio: true,      
      ),
    );
    
    // ব্রাউজারকে সিগনাল দেওয়া যে আমি এখন মাইক ব্যবহার করছি না
    await engine.muteLocalAudioStream(true);
    
    debugPrint("✅ Joined as Listener - No Green Dot");
  }

  // ২. সিটে বসার পর (এখন গ্রিন ডট আসবে)
  Future<void> becomeBroadcaster() async {
    // 🔥 Web-এর জন্য সিটে বসার সময় মাইক পারমিশন পপআপ বা একটিভ করা
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100);
    debugPrint("✅ Now Broadcaster - Green Dot should appear");
  }

  // বাকি toggleMic, becomeListener এবং leaveRoom আপনার আগের ফাইলের মতোই থাকবে...
  
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    if (!isMute) {
      await engine.enableLocalAudio(true);
    }
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    debugPrint("✅ Back to Listener");
  }

  Future<void> leaveRoom() async {
    try {
      await engine.leaveChannel();
      debugPrint("Left Voice Room");
    } catch (e) {
      debugPrint("Error leaving room: $e");
    }
  }
}
