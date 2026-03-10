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

    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    await engine.enableAudio();
    _isInitialized = true; 
  }

  // ১. ইউনিক আইডি জেনারেশন - যা ইউজারদের আলাদা রাখবে (Fix for Icon Disappearing)
  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    if (fireUid != null && fireUid.isNotEmpty) {
      // শুধু hashCode না নিয়ে, স্ট্রিং এর ক্যারেক্টার কোড সাম করে ছোট এবং ইউনিক আইডি বানানো
      // এটি এগোরা-র ৩২-বিট লিমিটের মধ্যে আইডি নিশ্চিত করবে
      int hash = 0;
      for (int i = 0; i < fireUid.length; i++) {
        hash = fireUid.codeUnitAt(i) + ((hash << 5) - hash);
      }
      _localUid = hash.abs() % 1000000; // ০ থেকে ৯৯৯৯৯৯ এর মধ্যে ইউনিক আইডি
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
    
    await engine.muteLocalAudioStream(true);
    debugPrint("✅ Joined with UID: $_localUid");
  }

  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      js.context.callMethod('eval', [
        """
        (function() {
          var audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)();
          if (audioCtx.state === 'suspended') {
            audioCtx.resume();
          }
          window.audioCtx = audioCtx;
        })();
        """
      ]);
    }
  }

  Future<void> becomeBroadcaster() async {
    await forceResumeAudio();
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
        js.context.callMethod('eval', [
          "window.micKeepAlive = setInterval(() => { if(window.audioCtx && window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 1000);"
        ]);
      } catch (e) {
        debugPrint("Mic Error: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(200);

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isInitialized) engine.muteLocalAudioStream(false);
    });
  }

  Future<void> toggleMic(bool isMute) async {
    if (!_isInitialized) return;
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    debugPrint("✅ Mic is now: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["if(window.micKeepAlive) clearInterval(window.micKeepAlive);"]);
    
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    if (kIsWeb) js.context.callMethod('eval', ["if(window.micKeepAlive) clearInterval(window.micKeepAlive);"]);
    try { 
      await engine.leaveChannel(); 
      _localUid = null; 
    } catch (e) {}
  }
}
