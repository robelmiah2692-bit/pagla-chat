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

  RtcEngine get engine {
    if (_engine == null) {
      debugPrint("⚠️ এগোরা ইঞ্জিন এখনো তৈরি হয়নি!");
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

      // মিউজিক এবং ভয়েস কোয়ালিটি উন্নত করার প্রোফাইল
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
        onAudioMixingStateChanged: (AudioMixingStateType state, AudioMixingReasonType reason) {
          if (state == AudioMixingStateType.audioMixingStatePlaying) {
            _isMusicPlaying = true;
          } else if (state == AudioMixingStateType.audioMixingStateStopped) {
            _isMusicPlaying = false;
          }
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

  // ১. গান শুরু করা (গ্যালারি বা স্টোরেজ থেকে)
  Future<void> startMusic(String filePath) async {
    if (_engine == null) return;
    try {
      await _engine!.startAudioMixing(
        filePath: filePath,
        loopback: true, // নিজে শোনার জন্য
        // replaceMic: false, // 👈 আপনার ভার্সনে এটি নেই, তাই এটি রিমুভ করা হলো
        cycle: -1, // আনলিমিটেড লুপ
      );
      _isMusicPlaying = true;
      debugPrint("🎵 মিউজিক মিক্সিং শুরু: $filePath");
    } catch (e) {
      debugPrint("❌ মিউজিক প্লে এরর: $e");
    }
  }

  // ২. গান বন্ধ করা
  Future<void> stopMusic() async {
    if (_engine == null) return;
    await _engine!.stopAudioMixing();
    _isMusicPlaying = false;
  }

  // ৩. গানের ভলিউম সেট করা
  Future<void> setMusicVolume(int volume) async {
    if (_engine == null) return;
    await _engine!.adjustAudioMixingVolume(volume);
  }

  // --- এন্ড অফ মিউজিক ফিচার ---

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
    
    // ৬.৫.৩ ভার্সনে 'publishAudioMixingTrack' নেই, তাই এটি রিমুভ করা হলো
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !_isMicMutedLocal, // মাইক স্ট্যাটাস অনুযায়ী
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    // হার্ডওয়্যার লেভেলে মাইক কন্ট্রোল
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
      // publishAudioMixingTrack: true, // 👈 এরর রিমুভ করা হলো
    ));
    
    await _engine!.enableLocalAudio(!isMute);
    debugPrint("🎤 Mic: ${isMute ? "OFF" : "ON"}, Music: Still Playing");
  }

  Future<void> becomeListener() async {
    if (_engine == null) return;
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    await stopMusic(); // লিসেনার হয়ে গেলে গান বন্ধ
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      // publishAudioMixingTrack: false, // 👈 এরর রিমুভ করা হলো
      autoSubscribeAudio: true,
    ));
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
