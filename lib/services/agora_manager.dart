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

    await engine.enableAudio();
    
    // নেটওয়ার্ক স্ট্যাবিলিটি সেটিংস
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized with Network Backup");
  }

  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    // প্রোফাইল আইডি থেকে ইউনিক সংখ্যা তৈরি (যাতে সবাইকে আলাদা চেনে)
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
        // এখান থেকে সেই এরর দেওয়া লাইনটি ফেলে দিয়েছি
      ),
    );
    
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
      options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
      ),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(150);

    // পালস লজিক: নেটওয়ার্ক ড্রপ সামলানোর জন্য
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(140); 
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
