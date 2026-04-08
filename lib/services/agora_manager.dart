import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

// 🛡️ পারমিশন হ্যান্ডলার ইমপোর্ট
import 'package:permission_handler/permission_handler.dart';

// 🛠️ এটি অ্যান্ড্রয়েড এবং ওয়েব দুই জায়গাতেই এরর ছাড়া চলে
import 'package:universal_html/html.dart' as html;
import 'package:universal_html/js.dart' as js;

class AgoraManager {
  RtcEngine? _engine; 
  bool _isInitialized = false;
  final String appId = "855883e294ec4144b8e955451c06e3d7";
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false;
  bool _isMicMutedLocal = false; // মাইকের বর্তমান অবস্থা ট্র্যাকিং
  bool _isMusicPlaying = false; // মিউজিক বাজছে কি না ট্র্যাকিং

   // ✅ সব রিমোট ইউজারের অডিও মিউট বা আনমিউট করার জন্য (Updated)
  Future<void> muteAllRemoteAudio(bool mute) async {
    if (_engine != null) {
      try {
        await _engine!.muteAllRemoteAudioStreams(mute);
        debugPrint("All remote audio ${mute ? 'muted' : 'unmuted'}");
      } catch (e) {
        debugPrint("Error in muteAllRemoteAudio: $e");
      }
    }
  }
  // 🔔 রিপেল এনিমেশনের ভলিউম স্ট্রিম
  final StreamController<List<AudioVolumeInfo>> _volumeStreamController = 
      StreamController<List<AudioVolumeInfo>>.broadcast();
  Stream<List<AudioVolumeInfo>> get volumeStream => _volumeStreamController.stream;

  // ✅ ফিক্সড গেটার: এটি এখন বিল্ড এরর দেবে না
  RtcEngine get engine {
    if (_engine == null) {
      throw Exception("এগোরা ইঞ্জিন এখনো তৈরি হয়নি! আগে initAgora() কল করুন।");
    }
    return _engine!;
  }

  int? get localUid => _localUid;

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

      await _engine!.enableAudioVolumeIndication(
        interval: 250,
        smooth: 3,
        reportVad: true,
      );

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("✅ এগোরা কানেক্টেড! UID: ${connection.localUid}");
          _localUid = connection.localUid;
          forceResumeAudio(); 
        },
        onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
          _volumeStreamController.add(speakers);
        },
        onAudioMixingStateChanged: (AudioMixingStateType state, AudioMixingReasonType reason) {
          _isMusicPlaying = (state == AudioMixingStateType.audioMixingStatePlaying);
        },
        onError: (err, msg) {
          debugPrint("❌ এগোরা এরর: $err - $msg");
        }
      ));

      await _engine!.enableAudio();
      _isInitialized = true;
    } catch (e) {
      debugPrint("❌ ইনিশিয়ালাইজ ফেল: $e");
    }
  }

  // --- মিউজিক ফিচারসমূহ ---
  Future<void> startMusic(String filePath) async {
    if (_engine == null) return;
    try {
      await _engine!.startAudioMixing(
        filePath: filePath,
        loopback: true, 
        cycle: -1, 
      );
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint("❌ মিউজিক প্লে এরর: $e");
    }
  }

  Future<void> stopMusic() async {
    if (_engine == null) return;
    await _engine!.stopAudioMixing();
    _isMusicPlaying = false;
  }

  Future<void> setMusicVolume(int volume) async {
    if (_engine == null) return;
    await _engine!.adjustAudioMixingVolume(volume);
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
        debugPrint("Resume Error: $e");
      }
    }
  }

  // --- সাইলেন্ট এন্ট্রি ফিক্স ---
  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized || _engine == null) await initAgora();

    _localUid = (fireUid != null && fireUid.isNotEmpty) 
        ? (fireUid.hashCode.abs() % 1000000) 
        : (Random().nextInt(899999) + 100000);

    await _engine!.joinChannel(
      token: "",
      channelId: channelName.trim(), 
      uid: _localUid!,
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

  // --- সিটে বসার পর কলিং ---
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

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isInitialized && _shouldBeBroadcasting) {
        _ensureAudioPublishing();
      }
    });
  }

  Future<void> _ensureAudioPublishing() async {
    if (_engine == null) return;
    
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !_isMicMutedLocal, 
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await _engine!.enableLocalAudio(!_isMicMutedLocal);
    
    if (!_isMicMutedLocal) {
      await _engine!.adjustRecordingSignalVolume(150); 
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
    _keepAliveTimer?.cancel();
    await stopMusic(); 
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      autoSubscribeAudio: true,
    ));
    await _engine!.enableLocalAudio(false); 
  }

  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    try {
      await stopMusic();
      if (_engine != null) await _engine!.leaveChannel();
      _localUid = null;
    } catch (e) {}
  }
}
