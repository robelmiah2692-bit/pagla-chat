import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:async';
import 'dart:math';
// ওয়েব ফিচারগুলোর জন্য এই কন্ডিশনাল ইমপোর্ট দরকার
import 'dart:html' as html;
import 'dart:js' as js;

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "855883e294ec4144b8e955451c06e3d7"; 
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false; 

  int? get localUid => _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    engine = createAgoraRtcEngine();
    
    // ✅ গ্লোবাল এরিয়া কোড (সঠিক সিনট্যাক্স সহ)
    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(), // ফাংশন হিসেবে কল করা হয়েছে
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // অডিও ভলিউম ট্র্যাকিং
    await engine.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true,
    );

    // 🔥 ওয়েব অপ্টিমাইজেশন প্যারামিটার
    if (kIsWeb) {
      await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
      await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    }

    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          _ensureAudioPublishing();
        }
      },
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ চ্যানেলে জয়েন সফল!");
      },
    ));

    await engine.enableAudio();
    _isInitialized = true; 
  }

  // ✅ ব্রাউজারের অডিও আটকে যাওয়া ঠেকাতে আসল লজিক
  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          """
          (function() {
            var audioCtx = window.audioCtx || new (window.AudioContext || window.webkitAudioContext)();
            if (audioCtx.state === 'suspended') { audioCtx.resume(); }
            window.audioCtx = audioCtx;
          })();
          """
        ]);
      } catch (e) {
        debugPrint("Audio Resume Error: $e");
      }
    }
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
        clientRoleType: ClientRoleType.clientRoleBroadcaster, 
        publishMicrophoneTrack: false, 
        autoSubscribeAudio: true,
      ),
    );
    _shouldBeBroadcasting = false;
  }

  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    // ✅ ব্রাউজার মাইক পারমিশন চেক
    if (kIsWeb) {
      try {
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic Permission Denied: $e");
      }
    }

    await forceResumeAudio();
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
