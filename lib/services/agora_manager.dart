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
  // আপনার নতুন ফ্রেশ আইডি
  final String appId = "855883e294ec4144b8e955451c06e3d7"; 
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false; 

  int? get localUid => _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    
    // ✅ গ্লোবাল রিজিয়ন (areaCodeGlob) যোগ করা হয়েছে যাতে কানেকশন মিস না হয়
    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value, 
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // অডিও ভলিউম ইন্ডিকেশন (রিপেল বা ঢেউয়ের জন্য)
    await engine.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true,
    );

    // --- নেটওয়ার্ক রেজিলিয়েন্স সেটআপ ---
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    await engine.setParameters('{"rtc.net_status_notification_interval":1000}');
    
    // ইভেন্ট হ্যান্ডলার
    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint("📡 Connection State: $state, Reason: $reason");
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          _ensureAudioPublishing();
        }
      },
      onRejoinChannelSuccess: (connection, elapsed) {
        debugPrint("🔄 অটো রিকানেক্ট সফল!");
        if (_shouldBeBroadcasting) _ensureAudioPublishing();
      },
      // ✅ এরর ধরার জন্য নতুন লগার যোগ করা হয়েছে
      onError: (ErrorCodeType err, String msg) {
        debugPrint("❌ Agora Error Code: $err, Message: $msg");
      },
    ));

    await engine.enableAudio();
    _isInitialized = true; 
    debugPrint("✅ Agora Initialized Globally with App ID: $appId");
  }

  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    if (fireUid != null && fireUid.isNotEmpty) {
      int hash = 0;
      for (int i = 0; i < fireUid.length; i++) {
        hash = fireUid.codeUnitAt(i) + ((hash << 5) - hash);
      }
      _localUid = hash.abs() % 1000000;
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
    _shouldBeBroadcasting = false;
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
    _shouldBeBroadcasting = true;
    await forceResumeAudio();
    
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic Permission Error: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _ensureAudioPublishing();

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized && _shouldBeBroadcasting) {
        _ensureAudioPublishing(); 
      }
    });
  }

  Future<void> _ensureAudioPublishing() async {
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(200);
  }

  Future<void> toggleMic(bool isMute) async {
    if (!_isInitialized) return;
    if (isMute) {
      await engine.muteLocalAudioStream(true);
      await engine.updateChannelMediaOptions(const ChannelMediaOptions(publishMicrophoneTrack: false));
    } else {
      await _ensureAudioPublishing();
    }
  }

  Future<void> becomeListener() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel(); 
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
  }

  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    try { 
      await engine.leaveChannel(); 
      _localUid = null; 
    } catch (e) {}
  }
}
