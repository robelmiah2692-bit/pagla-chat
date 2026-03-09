import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer; // ব্রাউজারকে জাগিয়ে রাখার জন্য টাইমার

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
    
    // 🔥 এখানে scenario পরিবর্তন করা হয়েছে যেন ব্রাউজার মাইক না কাটে
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming, 
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

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
    
    debugPrint("✅ Joined as Listener - No Green Dot");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    await engine.muteLocalAudioStream(false);
    await engine.enableLocalAudio(true);
    await engine.adjustRecordingSignalVolume(100);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    // 🔥 ম্যাজিক পার্ট: প্রতি ৫ সেকেন্ডে একবার ব্রাউজারকে 'ধাক্কা' দেওয়া
    // এটি আপনার স্ক্রিনে ট্যাপ করার মতোই কাজ করবে
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      engine.adjustRecordingSignalVolume(100); 
      debugPrint("💓 Keep-alive pulse sent to browser");
    });

    debugPrint("✅ Now Broadcaster - Keep-Alive Active");
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    if (!isMute) {
      await engine.enableLocalAudio(true);
    }
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); // টাইমার বন্ধ করা
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
    
    debugPrint("✅ Back to Listener");
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    try {
      await engine.leaveChannel();
      debugPrint("Left Voice Room");
    } catch (e) {
      debugPrint("Error leaving room: $e");
    }
  }
}
