import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
// ওয়েবের সিকিউরিটি বাধা ভাঙার জন্য এই লাইব্রেরিগুলো মাস্ট
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

    // ১. গ্লোবাল রিজিয়ন এবং হাই-কোয়ালিটি অডিও সেটআপ
    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ২. অডিও রিপেল বা ঢেউ সচল করা
    await engine.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    // ৩. ওয়েবের জন্য স্পেশাল অডিও প্যারামিটার (বটম-লেভেল ফিক্স)
    if (kIsWeb) {
      await engine.setParameters('{"rtc.web_receiver_report_interval":1000}');
      await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
      // ইকো এবং নয়েজ ক্যান্সেলেশন বুস্ট
      await engine.setParameters('{"che.audio.enable.aec":true}');
      await engine.setParameters('{"che.audio.enable.ans":true}');
    }

    engine.registerEventHandler(RtcEngineEventHandler(
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateConnected && _shouldBeBroadcasting) {
          _ensureAudioPublishing();
        }
      },
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ Agora Connected Successfully");
        forceResumeAudio(); // কানেক্ট হওয়া মাত্রই অডিও সচল করা
      },
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        // রিয়েল টাইম রিপেল ডাটা
      },
    ));

    await engine.enableAudio();
    _isInitialized = true;
  }

  // ✅ ব্রাউজারের অডিও সিকিউরিটি (Autoplay) বাইপাস করার মাস্টার লজিক
  Future<void> forceResumeAudio() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          """
          (function() {
            var resume = function() {
              var contexts = [];
              if (window.AudioContext) contexts.push(new AudioContext());
              if (window.webkitAudioContext) contexts.push(new webkitAudioContext());
              contexts.forEach(function(ctx) {
                if (ctx.state !== 'running') ctx.resume();
              });
            };
            // ইউজার যখনই স্ক্রিনে টাচ করবে বা ক্লিক করবে, অডিও সচল হবে
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
        clientRoleType: ClientRoleType.clientRoleBroadcaster, // অলওয়েজ ব্রডকাস্টার মুড ফর ডাটা ট্র্যাকিং
        publishMicrophoneTrack: false,
        autoSubscribeAudio: true,
      ),
    );
    _shouldBeBroadcasting = false;
    await forceResumeAudio();
  }

  // ✅ সিটে বসার পর মাইক ওপেন করার কমপ্লিট লজিক
  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;

    if (kIsWeb) {
      try {
        // ব্রাউজারকে বাধ্য করা মাইক পারমিশন পপ-আপ দেখানোর জন্য
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic Permission Error: $e");
      }
    }

    await forceResumeAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _ensureAudioPublishing();

    // কানেকশন ড্রপ হওয়া ঠেকাতে ১ সেকেন্ড পরপর হার্টবিট চেক
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
      await forceResumeAudio();
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
