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

    if (!kIsWeb) {
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

  // ১. রুমে জয়েন করা (সবুজ আইকন আসবে না)
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
    // ওয়েব ব্রাউজারের জন্য অতিরিক্ত সেফটি
    await engine.enableLocalAudio(false); 
    
    debugPrint("✅ Joined as Listener - No Green Dot");
  }

  // ২. সিটে বসার পর (গ্রিন ডট আসার মেইন ফাংশন)
  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ওয়েব ব্রাউজারে মাইক একটিভ করার আসল কমান্ড
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // 🔥 এখানে আমরা এগোরাকে জোর দিয়ে বলছি যে আমি এখন ব্রডকাস্টার
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // অডিও ট্র্যাকগুলো পুনরায় চেক করে অন করা
    await engine.muteLocalAudioStream(false);
    await engine.enableLocalAudio(true);
    await engine.adjustRecordingSignalVolume(100);
    
    // ওয়েব ব্রাউজারে অনেক সময় সাথে সাথে সিগনাল ধরে না, তাই আপডেট পাঠিয়ে দেওয়া
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    debugPrint("✅ Now Broadcaster - Green Dot Fixed");
  }

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
    
    // রোল চেঞ্জটা এগোরা সার্ভারে আপডেট করা
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
    
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
