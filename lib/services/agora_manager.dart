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

    engine = createAgoraRtcEngine();
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileSpeechStandard,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

  // ১. রুমে জয়েন করা (শুধুমাত্র লিসেনার হিসেবে - কোনো গ্রিন ডট আসবে না)
  Future<void> joinAsListener(String channelName) async {
    if (!_isInitialized) await initAgora();

    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: myUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience, 
        publishMicrophoneTrack: false, 
        autoSubscribeAudio: true,      
      ),
    );
    
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false); 
    
    debugPrint("✅ Joined as Listener - Mic off (No Green Dot)");
  }

  // ২. সিটে বসার পর মাইক সচল করা (এখুনি গ্রিন ডট আসবে)
  Future<void> becomeBroadcaster() async {
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100);
    debugPrint("✅ Now Broadcaster - Green Dot should appear");
  }

  // 🔥 ৩. আপনার UI-এর মাইক বাটনের জন্য (এটি গিটহাব এরর ফিক্স করবে)
  Future<void> toggleMic(bool isMute) async {
    // কথা বলতে চাইলে মাইক ডাটা অন করবে, মিউট করলে বন্ধ করবে
    await engine.muteLocalAudioStream(isMute);
    // যদি আনমিউট করা হয়, তবে অডিও সচল আছে কি না নিশ্চিত করা
    if (!isMute) {
      await engine.enableLocalAudio(true);
    }
    debugPrint("🎤 Mic state changed: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  // ৪. সিট থেকে নেমে গেলে মাইক বন্ধ করা (গ্রিন ডট চলে যাবে)
  Future<void> becomeListener() async {
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    debugPrint("✅ Back to Listener - Green Dot should disappear");
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
