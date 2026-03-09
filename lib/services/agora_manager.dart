import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      await [Permission.microphone].request();
    }

    engine = createAgoraRtcEngine();
    
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    await engine.enableAudio();
    
    // হাই কোয়ালিটি অডিও সেট করা যাতে ব্রাউজার কানেকশন না কাটে
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming, 
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

  Future<void> joinAsListener(String channelName) async {
    if (!_isInitialized) await initAgora();

    int myUid = DateTime.now().millisecondsSinceEpoch % 100000;

    await engine.joinChannel(
      token: "", 
      channelId: channelName, 
      uid: myUid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience, 
        publishMicrophoneTrack: false, 
        autoSubscribeAudio: true,      
      ),
    );
    
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false); 
    
    debugPrint("✅ Joined as Listener - No Green Dot");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ১. ব্রাউজার লেভেলে মাইক হার্ডওয়্যার সজাগ করা
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // ২. রোল ব্রডকাস্টার করা (সবুজ আইকন আসবে)
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // ৩. অডিও ইঞ্জিনকে রিফ্রেশ করা
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    
    // 🔥 ৪. সবচেয়ে গুরুত্বপূর্ণ: প্রিভিউ স্টার্ট করা (এটি ওয়েব ব্রাউজারকে ডাটা পাঠাতে বাধ্য করে)
    await engine.startPreview(); 

    // ৫. পাবলিশ অপশন কনফার্ম করা
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      // আওয়াজ ইন্টারনেটে পাঠাও
      autoSubscribeAudio: true,          // অন্যদের আওয়াজ আনো
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: false,
    ));

    await engine.muteLocalAudioStream(false);
    await engine.adjustRecordingSignalVolume(100);

    // 🔥 ৬. ওয়েব প্যারামিটার: এটি এগোরা সার্ভারের সাথে কথা বলা নিশ্চিত করবে
    await engine.setParameters('{"che.audio.opensl":true}'); 

    // ৭. কিপ-অ্যালাইভ পালস (ব্রাউজারকে জাগিয়ে রাখার জন্য)
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isInitialized) {
        // প্রতি ৫ সেকেন্ডে একবার মাইক ট্র্যাক রিফ্রেশ করা
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(100); 
        debugPrint("💓 Connection active - Streaming to Agora...");
      }
    });

    debugPrint("✅ Broadcaster fully active - Minutes should count now");
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
    await engine.stopPreview(); // প্রিভিউ বন্ধ করা
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await engine.muteLocalAudioStream(true);
    await engine.enableLocalAudio(false);
    
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: false,
      clientRoleType: ClientRoleType.clientRoleAudience,
    ));
    
    debugPrint("✅ Back to Listener");
  }

  Future<void> leaveRoom() async {
    _keepAliveTimer?.cancel();
    try {
      await engine.leaveChannel();
      debugPrint("Left Voice Room");
    } catch (e) {
      debugPrint("Error leaving room: $e");
    }
  }
}
