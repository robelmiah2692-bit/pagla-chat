import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/js.dart' as js;

class AgoraManager {
  RtcEngine? _engine;
  bool _isInitialized = false;
  final String appId = "855883e294ec4144b8e955451c06e3d7";
  int? _localuID;
  bool _shouldBeBroadcasting = false;
  bool _isMicMutedLocal = false;
  bool _isMusicPlaying = false;

  // 🔔 রিপেল এনিমেশনের জন্য সেপারেট স্ট্রিম কন্ট্রোলার (setState এড়াতে)
  final StreamController<List<AudioVolumeInfo>> _volumeStreamController =
      StreamController<List<AudioVolumeInfo>>.broadcast();
  Stream<List<AudioVolumeInfo>> get volumeStream =>
      _volumeStreamController.stream;

  RtcEngine get engine {
    if (_engine == null) {
      throw Exception("এগোরা ইঞ্জিন এখনো তৈরি হয়নি! আগে initAgora() কল করুন।");
    }
    return _engine!;
  }

  int? get localuID => _localuID;

  Future<void> initAgora() async {
    if (_isInitialized && _engine != null) return;

    
    _engine = createAgoraRtcEngine();

    try {
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        areaCode: AreaCode.areaCodeGlob.value(),
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQualityStereo,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      if (kIsWeb) {
        await _engine!.setParameters('{"rtc.audio.force_confirm_hello": true}');
        await _engine!.setParameters('{"che.audio.opensl": true}');
        await _engine!.setParameters('{"che.audio.specify.codec": "OPUS"}');
      }

      // ভলিউম ইনডিকেশন ফ্রিকোয়েন্সি অপ্টিমাইজড (৪০০ মিলিডেকেন্ড - হ্যাং এড়াতে)
      await _engine!.enableAudioVolumeIndication(
        interval: 400,
        smooth: 3,
        reportVad: true,
      );

      // সিঙ্গেল গ্লোবাল ইভেন্ট হ্যান্ডলার রেজিস্টার (ডুপ্লিকেট এড়াতে)
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _localuID = connection.localUid;
          
          forceResumeAudio();
        },
        onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
          if (!_volumeStreamController.isClosed) {
            _volumeStreamController.add(speakers);
          }
        },
        onAudioMixingStateChanged: (state, reason) {
          _isMusicPlaying = (state == AudioMixingStateType.audioMixingStatePlaying);
         
        },
        onError: (err, msg) {
          
        },
      ));

      await _engine!.enableAudio();
      _isInitialized = true;
      
    } catch (e) {
      
    }
  }

  Future<void> joinAsListener(String channelName, [String? fireuID]) async {
    if (!_isInitialized || _engine == null) await initAgora();

    _localuID = (fireuID != null && fireuID.isNotEmpty)
        ? (fireuID.hashCode.abs() % 1000000)
        : (Random().nextInt(899999) + 100000);

   

    await _engine!.joinChannel(
      token: "",
      channelId: channelName.trim(),
      uid: _localuID!,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: false,
        autoSubscribeAudio: true,
      ),
    );

    await _engine!.enableLocalAudio(false);
    _shouldBeBroadcasting = false;
    await forceResumeAudio();
  }

  Future<void> becomeBroadcaster() async {
    if (_engine == null) await initAgora();
    _shouldBeBroadcasting = true;
    _isMicMutedLocal = false;

    if (!kIsWeb) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        await Permission.microphone.request();
      }
    }

    
    await _engine!.enableLocalAudio(true);
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _ensureAudioPublishing();
  }

  Future<void> _ensureAudioPublishing() async {
    if (_engine == null) return;
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !_isMicMutedLocal,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await _engine!.enableLocalAudio(!_isMicMutedLocal);
  }

  // AgoraManager ক্লাসের ভেতরে এটি বসিয়ে দিন
Future<void> remoteMuteControl(bool isMute) async {
  if (_engine == null) return;
  _isMicMutedLocal = isMute;
  await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
    publishMicrophoneTrack: !isMute,
  ));
  await _engine!.enableLocalAudio(!isMute);
}
  
// AgoraManager ক্লাসের ভেতরে এটি বসিয়ে দিন
Future<void> muteAllRemoteAudio(bool mute) async {
  if (_engine != null) {
    try {
      await _engine!.muteAllRemoteAudioStreams(mute);
      
    } catch (e) {
      
    }
  }
}

  Future<void> toggleMic(bool isMute) async {
    if (_engine == null) return;
    _isMicMutedLocal = isMute;
    
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    await _engine!.enableLocalAudio(!isMute);
  }

  Future<void> becomeListener() async {
    if (_engine == null) return;
    _shouldBeBroadcasting = false;
    debugPrint("🎧 [Agora] Switching role back to Audience");
    await stopMusic();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      autoSubscribeAudio: true,
    ));
    await _engine!.enableLocalAudio(false);
  }

  Future<void> startMusic(String filePath) async {
    if (_engine == null) return;
    try {
      debugPrint("🎶 [Agora] Starting Music Mixing...");
      await _engine!.startAudioMixing(
        filePath: filePath,
        loopback: true,
        cycle: -1,
      );
      _isMusicPlaying = true;
    } catch (e) {
      
    }
  }

  Future<void> stopMusic() async {
    if (_engine == null) return;
    try {
      await _engine!.stopAudioMixing();
      _isMusicPlaying = false;
      
    } catch (e) {}
  }

  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          """
          (function() {
            var resume = function() {
              var AudioContext = window.AudioContext || window.webkitAudioContext;
              if (AudioContext) {
                var ctx = new AudioContext();
                if (ctx.state !== 'running') {
                  ctx.resume().then(() => console.log('Audio Context Resumed Success'));
                }
              }
            };
            window.addEventListener('click', resume, {once: false});
            window.addEventListener('touchstart', resume, {once: false});
            resume();
          })();
          """
        ]);
      } catch (e) {
        
      }
    }
  }

  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    try {
      await stopMusic();
      if (_engine != null) {
        // রুমে থেকে বের হওয়ার সময় অডিও পুরোপুরি বন্ধ এবং মিউট নিশ্চিত করা
        await _engine!.enableLocalAudio(false);
        await _engine!.muteAllRemoteAudioStreams(true);
        await _engine!.leaveChannel();
      }
      _localuID = null;
      debugPrint("🧹 [Agora] Successfully left room and cleaned audio tracks.");
    } catch (e) {
      debugPrint("❌ [Agora] Leave Room Error: $e");
    }
  }
}