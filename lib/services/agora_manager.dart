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
    
    // পারমিশন হ্যান্ডলিং
    if (!kIsWeb) {
      await [Permission.microphone].request();
    } else {
      // ওয়েব ব্রাউজারের জন্য মাইক্রোফোন পারমিশন প্রম্পট
      await html.window.navigator.getUserMedia(audio: true);
    }

    engine = createAgoraRtcEngine();
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ওয়েব অডিওর জন্য বিশেষ প্যারামিটার
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.opensl":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');

    await engine.enableAudio();
    _isInitialized = true; 
    debugPrint("Agora Initialized - Ready to Connect");
  }

  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    _localUid = fireUid?.hashCode.abs() ?? (Random().nextInt(899999) + 100000);

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
    debugPrint("✅ Joined Room: $channelName as Listener");
  }

  // কথা না আসার সমস্যা সমাধানের আসল ফাংশন
  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      js.context.callMethod('eval', [
        """
        (function() {
          var audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)();
          if (audioCtx.state === 'suspended') {
            audioCtx.resume().then(() => { console.log('AudioContext Resumed'); });
          }
          window.audioCtx = audioCtx;
        })();
        """
      ]);
    }
  }

  Future<void> becomeBroadcaster() async {
    await forceResumeAudio(); // সবার আগে অডিও ইঞ্জিন জাগানো

    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          "window.micKeepAlive = setInterval(() => { if(window.audioCtx && window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 1000);"
        ]);
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
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
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    if (kIsWeb) js.context.callMethod('eval', ["if(window.micKeepAlive) clearInterval(window.micKeepAlive);"]);
    try { await engine.leaveChannel(); _localUid = null; } catch (e) {}
  }
}
