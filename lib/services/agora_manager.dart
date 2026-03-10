import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:html' as html; 
import 'dart:async';
import 'dart:js' as js; 
import 'dart:math'; // আইডি তৈরির জন্য মাস্ট লাগবে

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;
  int? _localUid;

  Future<void> initAgora() async {
    if (_isInitialized) return;
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    // এই সেটিংসগুলো মাল্টি-ইউজার অডিওর জন্য সবচেয়ে শক্তিশালী
    await engine.setParameters('{"che.audio.enable.vqe":true}');
    await engine.setParameters('{"che.audio.live_for_comm":true}');
    await engine.setParameters('{"che.audio.specify.codec":"OPUS"}');
    
    _isInitialized = true; 
    debugPrint("Agora Initialized");
  }

  // এখানে [fireUid] অপশনাল রাখা হয়েছে যাতে আপনার বিল্ড ফেইল না হয়
  Future<void> joinAsListener(String channelName, [String? fireUid]) async {
    if (!_isInitialized) await initAgora();
    
    // 🔥 আইডি তৈরির সবচেয়ে শক্তিশালী লজিক যাতে কেউ কারও সাথে না মেলে
    if (fireUid != null && fireUid.isNotEmpty) {
      _localUid = fireUid.hashCode.abs() % 1000000;
    } else {
      // যদি ফায়ারবেস আইডি না পাওয়া যায়, তবে প্রতিবার আলাদা আইডি হবে
      _localUid = (Random().nextInt(900000) + 100000); 
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
    debugPrint("✅ Unique User Joined with UID: $_localUid");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ব্রাউজারকে বাধ্য করা অডিও সেশন চালু রাখতে
        js.context.callMethod('eval', [
          "var AudioContext = window.AudioContext || window.webkitAudioContext;"
          "var audioCtx = new AudioContext();"
          "audioCtx.resume();"
          "window.micKeepAlive = setInterval(function(){ if(audioCtx.state === 'suspended') audioCtx.resume(); }, 500);"
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

    // পালস লজিক: যাতে এগোরা মনে না করে ইউজার সাইলেন্ট আছে
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isInitialized) {
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(140); 
      }
    });
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
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
    if (kIsWeb) js.context.callMethod('eval', ["clearInterval(window.micKeepAlive);"]);
    try {
      await engine.leaveChannel();
      _localUid = null;
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}
