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

  // ১. এগোরা ইঞ্জিন সেটআপ (মাস্টার কনফিগ)
  Future<void> initAgora() async {
    if (_isInitialized) return;
    engine = createAgoraRtcEngine();

    await engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // অডিও রিপেল বা ঢেউ এনিমেশনের জন্য ভলিউম ডিটেকশন সচল করা
    await engine.enableAudioVolumeIndication(
      interval: 200, // আরও ফাস্ট ডিটেকশন
      smooth: 3,
      reportVad: true,
    );

    if (kIsWeb) {
      // ওয়েবে সাউন্ড কোয়ালিটি বুস্ট করার প্যারামিটার
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
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        // এখানে রিয়েল টাইম ভলিউম আসবে যা দিয়ে রিপেল নাচবে
        for (var speaker in speakers) {
          if (speaker.volume > 10) {
             // কথা বলার সময় ডাটা এখানে পাওয়া যাবে
          }
        }
      },
      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        debugPrint("🔊 রিমোট অডিও স্টেট: $state");
      }
    ));

    await engine.enableAudio();
    _isInitialized = true;
  }

  // ২. ব্রাউজার অডিও সিকিউরিটি বাইপাস (Autoplay Fix)
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

  // ৩. রুমে শ্রোতা হিসেবে জয়েন করা
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

  // ৪. সিটে বসলে মাইক সচল করা (Web Fix Included)
  Future<void> becomeBroadcaster() async {
    _shouldBeBroadcasting = true;
    
    if (kIsWeb) {
      try {
        // ব্রাউজারকে বাধ্য করা মাইক পারমিশন পপ-আপ দেখানোর জন্য
        await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
        debugPrint("🎤 Mic Permission Granted");
      } catch (e) {
        debugPrint("❌ Mic Permission Denied: $e");
      }
    }

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await forceResumeAudio();
    await _ensureAudioPublishing();

    // কিপ-অ্যালাইভ টাইমার যাতে ব্রাউজার কানেকশন না কাটে
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isInitialized && _shouldBeBroadcasting) {
        _ensureAudioPublishing();
      }
    });
  }

  // ৫. মাইক পাবলিশ করার কোর মেথড
  Future<void> _ensureAudioPublishing() async {
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    
    // ভলিউম ২০০% বুস্ট যাতে আওয়াজ ক্লিয়ার হয়
    await engine.adjustRecordingSignalVolume(200);
  }

  // ৬. মাইক মিউট/আনমিউট
  Future<void> toggleMic(bool isMute) async {
    if (!_isInitialized) return;
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
  }

  // ৭. সিট থেকে নামলে শ্রোতা হয়ে যাওয়া
  Future<void> becomeListener() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
    ));
    await engine.enableLocalAudio(false);
  }

  // ৮. রুম থেকে বের হওয়া
  Future<void> leaveRoom() async {
    _shouldBeBroadcasting = false;
    _keepAliveTimer?.cancel();
    try {
      await engine.leaveChannel();
      _localUid = null;
    } catch (e) {}
  }
}
