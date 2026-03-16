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

    // ১. ইনিশিয়ালাইজেশন (এরিয়া কোড গ্লোবাল রেখেছি টেস্টের জন্য)
    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // ২. ওয়েব ব্রাউজারের অডিও গেটওয়ে আনলক করা (মাস্টার ফিক্স)
    if (kIsWeb) {
      await engine.setParameters('{"rtc.audio.force_confirm_hello": true}');
      await engine.setParameters('{"che.audio.specify.codec": "OPUS"}');
      await engine.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
    }

    await engine.enableAudioVolumeIndication(
      interval: 250,
      smooth: 3,
      reportVad: true,
    );

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("✅ এগোরা কানেক্টেড! UID: ${connection.localUid}");
        forceResumeAudio(); 
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint("👥 অন্য ইউজার জয়েন করেছে: $remoteUid");
        // অন্য কেউ জয়েন করলে ব্রাউজার অডিও রিস্টার্ট করা জরুরি
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

    await engine.enableAudio();
    _isInitialized = true;
  }

  // ৩. ব্রাউজার অডিও আনলক করার মাস্টার মেথড
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
                  if (ctx.state !== 'running') {
                    ctx.resume().then(() => console.log('Audio Context Resumed Success'));
                  }
                }
              });
            };
            // ইউজারের যেকোনো টাচ বা ক্লিকে অডিও সচল হবে
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
    if (!_isInitialized) await initAgora();

    // ৪. ইউআইডি (UID) অবশ্যই পজিটিভ হতে হবে
    _localUid = (fireUid != null && fireUid.isNotEmpty) 
        ? fireUid.hashCode.abs() 
        : (Random().nextInt(899999) + 100000);

    await engine.joinChannel(
      token: "",
      channelId: channelName.trim(), // স্পেস থাকলে এরর দেয়, তাই ট্রিম করা
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

  // ৫. ব্রডকাস্টার হওয়ার জন্য পাওয়ারফুল কমান্ড
  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    if (kIsWeb) {
      try {
        // ব্রাউজারের কাছে মাইক পারমিশন চাওয়া
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      } catch (e) {
        debugPrint("Mic Hardware Permission Denied: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    
    await _ensureAudioPublishing();

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isInitialized && _shouldBeBroadcasting) {
        _ensureAudioPublishing();
      }
    });
  }

  Future<void> _ensureAudioPublishing() async {
    // অডিও স্ট্রীম জোর করে সার্ভারে পাঠানো এবং ভলিউম বুস্ট
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await engine.adjustRecordingSignalVolume(200); 
    await engine.adjustPlaybackSignalVolume(200);  
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
      autoSubscribeAudio: true,
    ));
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
