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
  final String appId = "855883e294ec4144b8e955451c06e3d7"; 
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false; // আঠার মতো লেগে থাকার জন্য ফ্ল্যাগ

  // ✅ গিটহাব এরর ফিক্স: বাইরের ফাইল থেকে uid পড়ার জন্য Getter
  int? get localUid => _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // 🔥 নতুন ফিচার: অডিও ভলিউম ইন্ডিকেশন চালু করা (পানির ঢেউয়ের জন্য)
    // এটি প্রতি ২০০ মিলিসেকেন্ড পরপর কে কথা বলছে তার ডাটা পাঠাবে
    await engine.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true,
    );

    // --- নেটওয়ার্ক রেজিলিয়েন্স সেটআপ (অটো রিকানেক্ট লজিক) ---
    await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    
    // কানেকশন লস্ট হলে যাতে দ্রুত ফিরে আসে তার প্যারামিটার
    await engine.setParameters('{"rtc.net_status_notification_interval":1000}');
    
    // ইভেন্ট হ্যান্ডলার যোগ করা (যাতে নেট ফিরে আসলে অটো কথা শুরু হয়)
    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint("📡 Connection State: $state, Reason: $reason");
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          // নেট ফিরে আসলে যদি সে সিটে থাকে, তবে অটো অডিও রি-পাবলিশ
          _ensureAudioPublishing();
        }
      },
      onRejoinChannelSuccess: (connection, elapsed) {
        debugPrint("🔄 অটো রিকানেক্ট সফল!");
        if (_shouldBeBroadcasting) _ensureAudioPublishing();
      },
    ));

    await engine.enableAudio();
    _isInitialized = true; 
  }

  // ইউনিক আইডি জেনারেশন (আইকন ফিক্স)
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

  // অডিও ইঞ্জিনকে আঠার মতো ধরে রাখা
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

    // 🔥 আঠার মতো লেগে থাকার মূল লজিক (Keep-Alive Timer)
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized && _shouldBeBroadcasting) {
        _ensureAudioPublishing(); // প্রতি ১ সেকেন্ডে অডিও চেক করবে
      }
    });
  }

  // অডিও পাবলিশিং নিশ্চিত করার প্রাইভেট ফাংশন
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
    // যদি ইউজার মিউট করে, তবে আঠার মতো লেগে থাকার লজিক সাময়িক থামবে
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
