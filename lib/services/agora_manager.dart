import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';
import 'dart:js' as js; 

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;
  int? _localUid;

  // ফায়ারবেসের স্ট্রিং ইউআইডি-কে এগোরা ফ্রেন্ডলি সংখ্যায় রূপান্তর (Fixed ID)
  int _createStaticId(String fireUid) {
    // এটি ফায়ারবেস আইডি থেকে একটি নির্দিষ্ট সংখ্যা তৈরি করবে যা কখনো পাল্টাবে না
    return fireUid.hashCode.abs() % 1000000;
  }

  Future<void> initAgora() async {
    if (_isInitialized) return;
    if (!kIsWeb) await [Permission.microphone].request();

    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    // মাল্টি-ইউজার অডিও মিক্সিং সেটিংস
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized");
  }

  // 👈 এখানে fireUid প্যারামিটারটি যোগ করেছি
  Future<void> joinAsListener(String channelName, String fireUid) async {
    if (!_isInitialized) await initAgora();
    
    // আপনার ফায়ারবেস আইডি থেকে স্থায়ী এগোরা আইডি তৈরি
    _localUid = _createStaticId(fireUid);

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
    debugPrint("Joined as Unique User: $_localUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', [
          "if(window.AudioContext || window.webkitAudioContext){"
          "var context = new (window.AudioContext || window.webkitAudioContext)();"
          "context.resume();"
          "window.agoraKeepAlive = setInterval(() => { if(context.state === 'suspended') context.resume(); }, 500);"
          "}"
        ]);
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    await engine.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
      options: const ClientRoleOptions(audienceLatencyLevel: AudienceLatencyLevelType.audienceLatencyLevelLowLatency),
    );
    
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.startPreview(); 

    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      
      autoSubscribeAudio: true,         
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(150);

    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        // ডাটা প্যাকেট পুশ (Force Push)
        engine.adjustRecordingSignalVolume(140); 
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.agoraKeepAlive);"]);
    
    await engine.stopPreview();
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.agoraKeepAlive);"]);
    try {
      await engine.leaveChannel();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
