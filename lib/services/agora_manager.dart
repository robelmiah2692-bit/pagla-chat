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
    
    if (!kIsWeb) {
      await [Permission.microphone].request();
    } else {
      try {
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic Permission Error: $e");
      }
    }

    engine = createAgoraRtcEngine();
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');

    await engine.enableAudio();
    _isInitialized = true; 
    debugPrint("Agora Initialized");
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
      js.context.callMethod('eval', [
        "window.micKeepAlive = setInterval(() => { if(window.audioCtx && window.audioCtx.state === 'suspended') window.audioCtx.resume(); }, 1000);"
      ]);
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

  // 🔥 আপনার মিসিং হওয়া toggleMic ফাংশনটি নিচে দেওয়া হলো
  Future<void> toggleMic(bool isMute) async {
    if (!_isInitialized) return;
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    debugPrint("Mic Toggled: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["if(window.micKeepAlive) clearInterval(window.micKeepAlive);"]);
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
