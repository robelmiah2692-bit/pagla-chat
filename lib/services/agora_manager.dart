import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

// ইউনিভার্সাল ইমপোর্ট লজিক যাতে বিল্ড ফেইল না হয়
import 'dart:js' as js;
import 'dart:html' as html;

class AgoraManager {
  RtcEngine? _engine; 
  bool _isInitialized = false;
  final String appId = "855883e294ec4144b8e955451c06e3d7";
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false;

  // আপনার রুম ডারট ফাইল থেকে এই 'engine' গেটারটিই কল করা হয়
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
        // 🔥 কলিং সমস্যা সমাধানের জন্য যোগ করা হয়েছে:
        await _engine!.setParameters('{"rtc.audio.force_confirm_hello": true}');
        await _engine!.setParameters('{"che.audio.opensl": true}'); // সাউন্ড ইঞ্জিন বুস্ট
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
          if (kIsWeb) {
            js.context.callMethod('alert', ["✅ কানেক্টেড!\nআপনার আইডি: ${connection.localUid}"]);
          }
          forceResumeAudio(); 
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint("👥 অন্য ইউজার জয়েন করেছে: $remoteUid");
          forceResumeAudio(); 
        },
        onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
          for (var speaker in speakers) {
            if ((speaker.volume ?? 0) > 10) {
              debugPrint("🎤 কথা বলছে UID: ${speaker.uid}");
            }
          }
        },
        onError: (err, msg) {
          debugPrint("❌ এগোরা এরর: $err - $msg");
        }
      ));

      await _engine!.enableAudio();
      _isInitialized = true;
    } catch (e) {
      if (kIsWeb) {
        js.context.callMethod('alert', ["❌ ইনিশিয়ালাইজ ফেল: $e"]);
      }
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
        ? (fireUid.hashCode.abs() % 1000000) // UID লিমিট করা হয়েছে
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
    
    if (kIsWeb) {
      try {
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      } catch (e) {
        js.context.callMethod('alert', ["❌ মাইক পারমিশন এরর: $e"]);
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
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await _engine!.enableLocalAudio(true);
    await _engine!.muteLocalAudioStream(false);
    
    // কথা পরিষ্কার যাওয়ার জন্য ভলিউম ২০০% করা হয়েছে
    await _engine!.adjustRecordingSignalVolume(200); 
    await _engine!.adjustPlaybackSignalVolume(200);  
  }

  Future<void> toggleMic(bool isMute) async {
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(isMute);
    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
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
