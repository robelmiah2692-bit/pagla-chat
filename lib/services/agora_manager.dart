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

      if (kIsWeb) {
        await _engine!.setParameters('{"rtc.audio.force_confirm_hello": true}');
        await _engine!.setParameters('{"che.audio.opensl": true}'); 
        await _engine!.setParameters('{"che.audio.specify.codec": "OPUS"}');
        
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioGameStreaming,
        );
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
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint("👥 অন্য ইউজার জয়েন করেছে: $remoteUid");
          forceResumeAudio(); 
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
    _isMicMutedLocal = false; // শুরুতে মাইক অন থাকবে
    
    if (!kIsWeb) {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        var result = await Permission.microphone.request();
        if (!result.isGranted) {
          debugPrint("❌ মাইক পারমিশন না দেওয়ায় ব্রডকাস্টিং সম্ভব নয়");
          return;
        }
      }
    }

    if (kIsWeb) {
      try {
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      } catch (e) {
        debugPrint("❌ ওয়েব মাইক পারমিশন এরর: $e");
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
    
    // যদি ইউজার ম্যানুয়ালি মাইক অফ করে থাকে, তবে পাবলিশ বন্ধ রাখতে হবে
    bool shouldPublish = _shouldBeBroadcasting && !_isMicMutedLocal;

    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: shouldPublish,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await _engine!.enableLocalAudio(shouldPublish);
    await _engine!.muteLocalAudioStream(!shouldPublish);
    
    if (shouldPublish) {
      await _engine!.adjustRecordingSignalVolume(200); 
      await _engine!.adjustPlaybackSignalVolume(200);  
    }
  }

  Future<void> toggleMic(bool isMute) async {
    if (_engine == null) return;
    _isMicMutedLocal = isMute; // লোকাল স্টেট আপডেট
    
    await _engine!.muteLocalAudioStream(isMute);
    await _engine!.enableLocalAudio(!isMute);
    
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    
    debugPrint("🎤 Mic Hardware Status: ${isMute ? "MUTED" : "UNMUTED"}");
  }

  Future<void> becomeListener() async {
    if (_engine == null) return;
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      autoSubscribeAudio: true,
    ));
  }

  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    try {
      if (_engine != null) await _engine!.leaveChannel();
      _localUid = null;
    } catch (e) {}
  }
}
