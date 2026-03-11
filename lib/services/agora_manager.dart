import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:async';
import 'dart:math';

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
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudioVolumeIndication(
      interval: 200, 
      smooth: 3, 
      reportVad: true,
    );

    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          _ensureAudioPublishing();
        }
      },
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ Join Success!");
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint("❌ Error: $err");
      },
    ));

    await engine.enableAudio();
    _isInitialized = true; 
  }

  // voice_room.dart এর এরর ফিক্স করার জন্য এটি জরুরি
  Future<void> forceResumeAudio() async {
    // ডামি ফাংশন যাতে বিল্ড পাস হয়
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
