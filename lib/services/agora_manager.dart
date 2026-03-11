import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:async';
import 'dart:math';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  // আপনার নতুন এবং ফ্রেশ অ্যাপ আইডি
  final String appId = "855883e294ec4144b8e955451c06e3d7"; 
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false; 

  int? get localUid => _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    engine = createAgoraRtcEngine();
    
    // একদম বেসিক ইনিশিয়ালাইজেশন যা সব ফ্লাটার ভার্সনে কাজ করবে
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // অডিও ভলিউম ট্র্যাকিং
    await engine.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true,
    );

    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        debugPrint("📡 Agora Status: $state");
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          _ensureAudioPublishing();
        }
      },
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ জয়েন সফল হয়েছে!");
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint("❌ এরর: $err");
      },
    ));

    await engine.enableAudio();
    _isInitialized = true; 
  }

  // শ্রোতা হিসেবে জয়েন করলেও রোল 'Broadcaster' রাখা হয়েছে যাতে ডাটা শো করে
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

  // কথা বলার জন্য মিক অন করা
  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
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
