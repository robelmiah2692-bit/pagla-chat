import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';
import 'dart:js' as js; // এটি মোবাইল ব্রাউজার গেটওয়ে খোলার জন্য

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;

  Future<void> initAgora() async {
    if (_isInitialized) return;
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    _isInitialized = true; 
    debugPrint("Agora Initialized");
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
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // 🔥 মোবাইল ক্রোমের অডিও গেটওয়ে খোলার হার্ড লজিক
        js.context.callMethod('eval', [
          "if(window.AudioContext || window.webkitAudioContext){"
          "var context = new (window.AudioContext || window.webkitAudioContext)();"
          "context.resume().then(() => { console.log('Playback resumed successfully'); });"
          "}"
        ]);
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // রোল এবং ইঞ্জিন সেটিংস
    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: const ClientRoleOptions(audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.startPreview(); 

    // পাবলিশিং নিশ্চিত করা
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100);

    // ৩ সেকেন্ডের পালস
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        debugPrint("💓 Connection active - minutes adding...");
      }
    });
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    try { await engine.leaveChannel(); } catch (e) {}
  }
}
