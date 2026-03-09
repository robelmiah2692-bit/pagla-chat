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

    // অডিও ইঞ্জিন এনাবল করা
    await engine.enableAudio();
    
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
    
    debugPrint("✅ Joined as Listener");
  }

  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ১. ব্রাউজার লেভেলে মাইক নিশ্চিত করা
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // ২. রোল চেঞ্জ (সবুজ আইকন আসবে)
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // ৩. অডিও সোর্সগুলো সজাগ করা
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    
    // 🔥 ৪. এই অংশটিই আপনার ড্যাশবোর্ডে মিনিট যোগ করবে
    // আমরা এগোরাকে ফোর্স করছি অডিও ডাটা পাবলিশ করতে
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      // আওয়াজ ইন্টারনেটে পাঠাও
      autoSubscribeAudio: true,         // অন্যের আওয়াজ আনো
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: false,
    ));

    await engine.adjustRecordingSignalVolume(100);

    // ৫. কিপ-অ্যালাইভ পালস (ব্রাউজারকে জাগিয়ে রাখার জন্য)
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isInitialized) {
        // অডিও ট্র্যাক রিফ্রেশ করা
        engine.muteLocalAudioStream(false);
        engine.adjustRecordingSignalVolume(100); 
        debugPrint("💓 Pulse sent - Server connection active");
      }
    });

    debugPrint("✅ Broadcaster fully active - Minutes should start adding");
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    // মিউট বা আনমিউট করলে সার্ভারকে আপডেট জানানো
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  Future<void> becomeListener() async {
    _keepAliveTimer?.cancel(); 
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
