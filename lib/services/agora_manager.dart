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

    // অডিও ভলিউম ইন্ডিকেশন (রিপেল বা ঢেউ এনিমেশনের জন্য)
    await engine.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    if (kIsWeb) {
      // ওয়েব অডিও প্যারামিটার বুস্ট
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
        debugPrint("🔊 রিমোট অডিও স্টেট পরিবর্তন: $state");
      }
    ));

    await engine.enableAudio();
    _isInitialized = true;
  }

  // মাস্টার অডিও রেজুউম (ব্রাউজার সিকিউরিটি বাইপাস)
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

  // 🔥 এই ফাংশনটি এখন সরাসরি ব্রাউজার থেকে মাইক পারমিশন চাইবে
  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    if (kIsWeb) {
      try {
        // ১. ব্রাউজার নেটিভ API দিয়ে জোর করে পারমিশন পপ-আপ আনা
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
        debugPrint("🎤 ব্রাউজার মাইক পারমিশন দিয়েছে");
      } catch (e) {
        debugPrint("❌ পারমিশন এরর: $e");
        // যদি ইউজার পারমিশন না দেয়, তবে কথা বলা সম্ভব নয়
      }
    }

    // ২. রোলে পরিবর্তন
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // ৩. অডিও ইঞ্জিন এবং পারমিশন সিকোয়েন্স
    await forceResumeAudio();
    
    // ৪. মাইক্রোফোন পাবলিশ করা
    await _ensureAudioPublishing();

    // ৫. কিপ-অ্যালাইভ (যাতে ব্রাউজার অডিও চ্যানেল বন্ধ না করে)
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
    
    // ভলিউম একটু বুস্ট করে দেওয়া হলো যাতে কথা ক্লিয়ার শোনা যায়
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
