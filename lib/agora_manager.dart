import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraManager {
  late RtcEngine engine;
  // আপনার দেওয়া এগোরা আইডি
  String appId = "bd010dec4aa141228c87ec2cb9d4f6e8"; 

  Future<void> initAgora() async {
    await [Permission.microphone].request();
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));

    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQuality,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );
  }

  // সিটে বসার পর কলিং শুরু হবে
  Future<void> joinRoom(String channelName) async {
    await engine.joinChannel(
      token: "", // টেস্টের জন্য আপাতত খালি
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> toggleMic(bool isMute) async {
    await engine.muteLocalAudioStream(isMute);
  }

  Future<void> leaveRoom() async {
    await engine.leaveChannel();
  }
}
