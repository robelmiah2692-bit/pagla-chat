import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
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
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    
    // 💡 ফিচার ১: নেটওয়ার্ক লজিক অ্যাড করা হয়েছে (Reconnection Policy)
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    
    // নেট স্লো হলেও যেন কানেকশন ধরে রাখে তার প্যারামিটার
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    
    // নেটওয়ার্ক রিকানেক্ট হওয়ার জন্য ১ সেকেন্ড বিরতি সেট করা
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized with Network Backup");
  }

  // 💡 ফিচার ২: এখানে fireUid-কে কাজে লাগানো হয়েছে (Unique User Logic)
  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
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
        // নেট ডিসকানেক্ট হলে অটো ট্রাই করবে
        enableAudioRecordingDevice: true, 
      ),
    );
    
    // অন্যের আওয়াজ শোনার গেট খোলা
    await engine.muteAllRemoteAudioStreams(false);
    debugPrint("✅ Joined UID: $_localUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          "if(!window.audioCtx){ window.audioCtx = new (window.AudioContext || window.webkitAudioContext)(); }"
          "window.audioCtx.resume();"
          "window.micKeepAlive = setInterval(() => { if(window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 500);"
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
    await engine.adjustRecordingSignalVolume(150);

    // 💡 নেটওয়ার্ক অটো-হিলিং পালস
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        // নেট ২-৩ সেকেন্ডের জন্য চলে গিয়ে আবার আসলে মাইক নিজেই অন হবে
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
    await engine.updateChannelMediaOptions(ChannelMediaOptions(publishMicrophoneTrack: !isMute));
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
    try { await engine.leaveChannel(); _localUid = null; } catch (e) {}
  }
}
