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
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // নেটওয়ার্ক রিকানেকশন সেটিংস (আঠার মতো লেগে থাকবে)
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    await engine.setParameters('{"che.audio.keep_audiosession_alive":true}');

    await engine.enableAudio();
    _isInitialized = true; 
    debugPrint("Agora Initialized - Ready to Connect");
  }

  // এখানে [String? fireUid] রেখেছি যাতে আপনি পাঠালেও কাজ করে, না পাঠালেও বিল্ড না ভাঙে
  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    // ইউনিক আইডি জেনারেশন - যাতে প্রত্যেক ইউজার আলাদা হয়
    if (fireUid != null && fireUid.toString().isNotEmpty) {
      _localUid = fireUid.hashCode.abs() % 1000000;
    } else {
      // যদি আইডি না পাঠান, তবে র‍্যান্ডম আইডি তৈরি হবে (বিল্ড ফেইল হবে না)
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
    
    await engine.muteAllRemoteAudioStreams(false);
    await engine.adjustPlaybackSignalVolume(150); // সাউন্ড বুস্ট
    debugPrint("✅ Joined Room: $channelName with UID: $_localUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // জাভাস্ক্রিপ্ট দিয়ে ব্রাউজারের অডিও ইঞ্জিনকে জাগিয়ে রাখা
        js.context.callMethod('eval', [
          "if(!window.audioCtx){ window.audioCtx = new (window.AudioContext || window.webkitAudioContext)(); }"
          "window.audioCtx.resume();"
          "window.micKeepAlive = setInterval(() => { if(window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 1000);"
        ]);
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: const ClientRoleOptions(
        audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
      ),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);

    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(200);

    // নেটওয়ার্ক স্লো হলে অটো-রিকানেক্ট পালস
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(150);
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
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
