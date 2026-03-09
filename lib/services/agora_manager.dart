import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';
import 'dart:js' as js; 
import 'dart:math'; // 👈 এটি জরুরি ইউনিক আইডি তৈরির জন্য

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;
  int? _currentUid; // নিজের আইডি মনে রাখার জন্য

  Future<void> initAgora() async {
    if (_isInitialized) return;
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    
    // 🔥 মাল্টি-ইউজার অডিও ব্যালেন্স করার প্যারামিটার
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized");
  }

  Future<void> joinAsListener(String channelName) async {
    if (!_isInitialized) await initAgora();
    
    // 🔥 ইউনিক আইডি জেনারেশন (Conflict এড়ানোর জন্য)
    _currentUid = Random().nextInt(899999) + 100000; 

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: _currentUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience, 
        publishMicrophoneTrack: false, 
        autoSubscribeAudio: true,      
      ),
    );
    debugPrint("Joined with Unique UID: $_currentUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          "if(window.AudioContext){"
          "var ctx = new AudioContext();"
          "ctx.resume();"
          "window.agoraAudioInterval = setInterval(() => { if(ctx.state === 'suspended') ctx.resume(); }, 1000);"
          "}"
        ]);
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: const ClientRoleOptions(audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.startPreview(); 

    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(150); // 👈 ভলিউম একটু বুস্ট করা হয়েছে

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        // ডাটা প্যাকেট সচল রাখার জন্য পালস
        engine.adjustRecordingSignalVolume(130); 
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.agoraAudioInterval);"]);
    
    await engine.stopPreview();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.agoraAudioInterval);"]);
    try {
      await engine.leaveChannel();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
