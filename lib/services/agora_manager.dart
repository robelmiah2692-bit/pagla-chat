import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;

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

    // অডিও ইঞ্জিন এনাবল করা
    await engine.enableAudio();
    
    // হাই কোয়ালিটি অডিও লক করা
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming, 
    );

    // 🔥 কানেকশন ডাটা ট্রান্সফার মোড অন করা
    await engine.setParameters('{"rtc.dual_stream_mode":true}');
    await engine.setParameters('{"che.audio.keep.audiosession":true}');
    
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
    
    debugPrint("✅ Joined as Listener");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ব্রাউজার লেভেলে মাইক হার্ডওয়্যার কনফার্ম করা
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // ১. রোল ব্রডকাস্টার করা (Low Latency অপশন সহ)
    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: const ClientRoleOptions(
        audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency
      ),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.startPreview(); 

    // ২. পাবলিশিং লজিক (এটি মিনিট যোগ করার মেইন লক)
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: false,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100);

    // ৩. ওয়েব প্যারামিটার (সার্ভারের সাথে কানেকশন লক করা)
    await engine.setParameters('{"che.audio.opensl":true}'); 
    await engine.setParameters('{"che.audio.live_for_comm":true}');

    // ৪. কিপ-অ্যালাইভ পালস (৩ সেকেন্ড পর পর রিফ্রেশ)
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(100); 
        debugPrint("💓 Connection active - minutes adding...");
      }
    });

    debugPrint("✅ Broadcaster Active - Connection Locked");
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    await engine.stopPreview();
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
