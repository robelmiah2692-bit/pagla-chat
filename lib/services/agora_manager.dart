import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart'; // 👈 এটি আবার যোগ করা হয়েছে
import 'dart:html' as html; 
import 'dart:async';
import 'dart:js' as js; 
import 'dart:math';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;
  int? _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;
    
    // মোবাইল ডিভাইসের জন্য পারমিশন চেক
    if (!kIsWeb) {
      await [Permission.microphone].request();
    }

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    // মাল্টি-ইউজার অডিও মিক্সিং সেটিংস
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized");
  }

  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    // ইউনিক আইডি জেনারেশন যাতে এগোরা সবাইকে আলাদা মানুষ মনে করে
    if (fireUid != null && fireUid.isNotEmpty) {
      _localUid = fireUid.hashCode.abs() % 1000000;
    } else {
      _localUid = (Random().nextInt(899999) + 100000); 
    }

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: _localUid!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience, 
        publishMicrophoneTrack: false, 
        autoSubscribeAudio: true,      
      ),
    );
    debugPrint("✅ Joined UID: $_localUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // 🔥 ব্রাউজারের মাইক আইকন সচল রাখার জন্য ডাবল-গার্ড লজিক
        js.context.callMethod('eval', [
          "if(!window.audioCtx){"
          "window.audioCtx = new (window.AudioContext || window.webkitAudioContext)();"
          "}"
          "window.audioCtx.resume();"
          "window.micKeepAlive = setInterval(() => { if(window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 500);"
        ]);
        
        // এটি ব্রাউজারকে সিগনাল দেয় যে মাইক ব্যবহার হচ্ছে
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
    await engine.adjustRecordingSignalVolume(150);

    // পালস লজিক যাতে কানেকশন ড্রপ না হয়
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(135); 
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
    
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
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
    try {
      await engine.leaveChannel();
      _localUid = null;
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
