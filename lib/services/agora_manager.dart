import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html; 
import 'dart:async';

class AgoraManager {
  late RtcEngine engine;
  bool _isInitialized = false; 
  final String appId = "32133508104045b687aae00c5ccc59a5"; 
  Timer? _keepAliveTimer; // ব্রাউজারকে জাগিয়ে রাখার জন্য টাইমার

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
    
    // হাই কোয়ালিটি অডিও সেট করা যাতে ব্রাউজার কানেকশন না কাটে
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming, 
    );
    
    _isInitialized = true; 
    debugPrint("Agora Initialized: $appId");
  }

  // ১. রুমে জয়েন করা (লিসেনার হিসেবে)
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

  // ২. সিটে বসার পর (গ্রিন ডট আসবে এবং কথা শোনা যাবে)
  Future<void> becomeBroadcaster() async {
    if (kIsWeb) {
      try {
        // ব্রাউজারের মাইক স্ট্রিমিং সচল করা
        await html.window.navigator.getUserMedia(audio: true);
      } catch (e) {
        debugPrint("Mic access failed: $e");
      }
    }

    // রোল ব্রডকাস্টার করা
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // অডিও ট্র্যাকগুলো অন করা
    await engine.enableAudio();
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);
    
    // 🔥 কথা শোনানোর মেইন ফিক্স: পাবলিশ অপশন কনফার্ম করা
    await engine.updateChannelMediaOptions(const ChannelMediaOptions(
      publishMicrophoneTrack: true,      // আওয়াজ সবার কাছে পাঠাবে
      autoSubscribeAudio: true,          // অন্যদের আওয়াজ আনবে
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ));

    await engine.adjustRecordingSignalVolume(100);

    // 🔥 ব্রাউজারকে জাগিয়ে রাখা (আপনার স্ক্রিন ট্যাপ করার বিকল্প)
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isInitialized) {
        engine.adjustRecordingSignalVolume(100); 
        debugPrint("💓 Keep-alive pulse sent to browser");
      }
    });

    debugPrint("✅ Now Broadcaster - Voice & Green Dot Active");
  }

  // ৩. মাইক মিউট/আনমিউট বাটন ফিচার
  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
    // আনমিউট করলে অডিও ট্র্যাক যেন সচল থাকে
    await engine.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: !isMute,
    ));
    if (!isMute) {
      await engine.enableLocalAudio(true);
    }
    debugPrint("🎤 Mic state: ${isMute ? 'Muted' : 'Unmuted'}");
  }

  // ৪. সিট ছাড়লে লিসেনার মোডে ফিরে যাওয়া
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
