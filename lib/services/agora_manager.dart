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

    // অডিও ভলিউম ইন্ডিকেশন (রিপেল এর জন্য)
    await engine.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    if (kIsWeb) {
      // ওয়েবে সাউন্ড কোয়ালিটি এবং কানেকশন ধরে রাখার মাস্টার প্যারামিটার
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
        debugPrint("👥 অন্য ইউজার জয়েন করেছে: $remoteUid");
      },
      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        debugPrint("🔊 রিমোট অডিও স্টেট: $state ইউজার: $remoteUid");
      }
    ));

    await engine.enableAudio();
    _isInitialized = true;
  }

  // ব্রাউজার অডিও রেজুউম (মাস্টার ফিক্স)
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

    // UID জেনারেশন লজিক (Collision এড়ানোর জন্য আরও ইউনিক করা হয়েছে)
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
        clientRoleType: ClientRoleType.clientRoleAudience, // শুরুতে শ্রোতা
        publishMicrophoneTrack: false,
        autoSubscribeAudio: true,
      ),
    );
    _shouldBeBroadcasting = false;
    await forceResumeAudio();
  }

  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    // ১. রোলে পরিবর্তন
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // ২. ওয়েব পারমিশন এবং অডিও রেজুউম
    await forceResumeAudio();
    
    // ৩. মাইক্রোফোন পাবলিশ করা
    await _ensureAudioPublishing();

    // ৪. কিপ-অ্যালাইভ টাইমার (যাতে ব্রাউজার অডিও ড্রপ না করে)
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
  }

  Future<void> toggleMic(bool isMute) async {
    if (!_isInitialized) return;
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(publishMicrophoneTrack: !isMute));
  }

  Future<void> becomeListener() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(publishMicrophoneTrack: false));
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
