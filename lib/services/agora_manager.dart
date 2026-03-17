import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'dart:html' as html;
import 'dart:js' as js;

class AgoraManager {
  RtcEngine? _engine; 
  bool _isInitialized = false;
  final String appId = "855883e294ec4144b8e955451c06e3d7";
  Timer? _keepAliveTimer;
  int? _localUid;
  bool _shouldBeBroadcasting = false;

  // আপনার পুরাতন ফাইলের সাথে মিল রাখতে গেটার রাখা হলো
  RtcEngine? get engine => _engine;

  int? get localUid => _localUid;

  Future<void> initAgora() async {
    if (_isInitialized && _engine != null) return;
    
    try {
      _engine = createAgoraRtcEngine();
      await _engine?.initialize(RtcEngineContext(
        appId: appId,
        areaCode: AreaCode.areaCodeGlob.value(),
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      if (kIsWeb) {
        // ওয়েব-স্পেসিফিক প্যারামিটার
        await _engine?.setParameters('{"rtc.audio.force_confirm_hello": true}');
        await _engine?.setParameters('{"che.audio.specify.codec": "OPUS"}');
      }

      _engine?.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("✅ এগোরা কানেক্টেড! UID: ${connection.localUid}");
          _localUid = connection.localUid;
          if (kIsWeb) {
            js.context.callMethod('alert', ["✅ কানেক্টেড!\nআইডি: ${connection.localUid}"]);
          }
          forceResumeAudio(); 
        },
        onError: (err, msg) {
          debugPrint("❌ এগোরা এরর: $err - $msg");
        }
      ));

      await _engine?.enableAudio();
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
                  ctx.resume().then(() => console.log('Audio Context Resumed'));
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
        ? (fireUid.hashCode.abs() + Random().nextInt(10000)) 
        : (Random().nextInt(800000) + 100000);

    await _engine?.joinChannel(
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
        debugPrint("Mic Permission Error: $e");
      }
    }

    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
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
    await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await _engine?.enableLocalAudio(true);
    await _engine?.muteLocalAudioStream(false);
  }

  Future<void> toggleMic(bool isMute) async {
    if (_engine == null) return;
    await _engine?.muteLocalAudioStream(isMute);
    await _engine?.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
  }

  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    try {
      await _engine?.leaveChannel();
      _localUid = null;
    } catch (e) {}
  }
}
