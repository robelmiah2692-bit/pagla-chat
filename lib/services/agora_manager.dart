import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
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

    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    if (kIsWeb) {
      await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
      await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQualityStereo,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
    }

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ Agora Connected. UID: ${connection.localUid}");
        forceResumeAudio(); 
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint("👥 User joined: $remoteUid");
      },
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        for (var speaker in speakers) {
          // 🔥 বিল্ড এরর ফিক্স: volume null হলে ০ ধরা হবে
          if ((speaker.volume ?? 0) > 10) {
            debugPrint("🎤 UID: ${speaker.uid} is speaking");
          }
        }
      },
      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        debugPrint("🔊 Remote Audio State: $state");
      }
    ));

    await engine.enableAudio();
    _isInitialized = true;
  }

  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          """
          (function() {
            var resume = function() {
              [window.AudioContext, window.webkitAudioContext].forEach(function(Context) {
                if (Context) {
                  var ctx = new Context();
                  if (ctx.state !== 'running') ctx.resume();
                }
              });
            };
            document.body.addEventListener('click', resume, {once: false});
            document.body.addEventListener('touchstart', resume, {once: false});
            resume();
          })();
          """
        ]);
      } catch (e) {
        debugPrint("Force Resume Error: $e");
      }
    }
  }

  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();

    if (fireUid != null && fireUid.isNotEmpty) {
      _localUid = fireUid.hashCode.abs();
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
    await forceResumeAudio();
  }

  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    if (kIsWeb) {
      try {
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      } catch (e) {
        debugPrint("Mic Permission Error: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await forceResumeAudio();
    await _ensureAudioPublishing();

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
  }

  Future<void> becomeListener() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
    ));
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
