import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'agora_manager.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'call_handler.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final String peerName;
  final String peerPic;
  final String myName;
  final String myPic;
  final bool isCaller;
  final String myId;
  final String targetId;

  const CallScreen({
    Key? key,
    required this.channelId,
    required this.peerName,
    required this.peerPic,
    required this.myName,
    required this.myPic,
    required this.isCaller,
    required this.myId,
    required this.targetId,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late final AgoraManager _agoraManager;
  bool _remoteUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _peerMuted = false; 
  Timer? _callTimer;
  int _secondsElapsed = 0;

  late AnimationController _rippleController;
  StreamSubscription<DocumentSnapshot>? _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _agoraManager = AgoraManager();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startCallSetup();
    _listenToCallState();
  }

  Future<void> _startCallSetup() async {
    await _agoraManager.initAgora();

    _agoraManager.engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUserJoined = true;
          });
          CallHandler.stopRinging();
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUserJoined = false;
          });
          _endCall(isRemoteEnd: true);
        },
      ),
    );

    await _agoraManager.joinForPersonalCall(widget.channelId, widget.myId);
  }

  void _listenToCallState() {
    String docId = widget.isCaller ? widget.targetId : widget.myId;
    _callStateSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        _endCall(isRemoteEnd: true);
      } else {
        var data = snapshot.data();
        if (data != null) {
          if (data['status'] == 'accepted') {
            if (!_remoteUserJoined) {
              setState(() {
                _remoteUserJoined = true;
              });
              CallHandler.stopRinging();
              _startTimer();
            }
          }

          bool remoteMutedStatus = widget.isCaller
              ? (data['receiverMuted'] ?? false)
              : (data['callerMuted'] ?? false);

          if (_peerMuted != remoteMutedStatus) {
            setState(() {
              _peerMuted = remoteMutedStatus;
            });
          }
        }
      }
    });
  }

  void _startTimer() {
    if (_callTimer != null && _callTimer!.isActive) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = remainingSeconds.toString().padLeft(2, '0');
    return "$minStr:$secStr";
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _agoraManager.toggleMic(_isMuted);

    String docId = widget.isCaller ? widget.myId : widget.targetId;
    String fieldName = widget.isCaller ? 'callerMuted' : 'receiverMuted';
    await FirebaseFirestore.instance.collection('calls').doc(docId).update({
      fieldName: _isMuted,
    });
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _agoraManager.engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _sendCallLogToFirestore(String status, String duration) async {
    List<String> ids = [widget.myId, widget.targetId];
    ids.sort();
    String chatId = ids.join("_");

    Map<String, dynamic> callLogMessage = {
      'senderId': widget.myId,
      'receiverId': widget.targetId,
      'type': 'call_log',
      'callStatus': status,
      'duration': duration,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(callLogMessage);

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': "Call: $status",
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _endCall({bool isRemoteEnd = false}) async {
    CallHandler.stopRinging();
    _callTimer?.cancel();
    _callStateSubscription?.cancel();

    String status = _remoteUserJoined ? 'received' : (widget.isCaller ? 'cancelled' : 'missed');
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    String duration = "$minutes min $seconds sec";

    await _sendCallLogToFirestore(status, duration);

    if (!isRemoteEnd) {
      String docId = widget.isCaller ? widget.targetId : widget.myId;
      try {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(docId)
            .delete();
      } catch (e) {
        debugPrint("Error deleting call doc: $e");
      }
    }

    await _agoraManager.leaveRoom();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    CallHandler.stopRinging();
    _callTimer?.cancel();
    _callStateSubscription?.cancel();
    _rippleController.dispose();
    _agoraManager.leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0D0D1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Column(
                  children: [
                    Text(
                      widget.peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _remoteUserJoined
                          ? _formatTime(_secondsElapsed)
                          : "Ringing...",
                      style: TextStyle(
                        color: _remoteUserJoined
                            ? Colors.greenAccent
                            : Colors.white70,
                        fontSize: _remoteUserJoined ? 20 : 16,
                        fontWeight: _remoteUserJoined
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_remoteUserJoined)
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildRippleCircle(_rippleController.value * 50),
                              _buildRippleCircle(
                                  (_rippleController.value + 0.5) % 1.0 * 50),
                            ],
                          );
                        },
                      ),
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: widget.peerPic.isNotEmpty
                          ? NetworkImage(widget.peerPic)
                          : const NetworkImage(
                              'https://via.placeholder.com/150'),
                    ),
                    if (_peerMuted)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.mic_off,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: widget.myPic.isNotEmpty
                                ? NetworkImage(widget.myPic)
                                : const NetworkImage(
                                    'https://via.placeholder.com/150'),
                          ),
                          if (_isMuted)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic_off,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: "mute",
                      backgroundColor:
                          _isMuted ? Colors.redAccent : Colors.white24,
                      onPressed: _toggleMute,
                      child: Icon(_isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white),
                    ),
                    FloatingActionButton(
                      heroTag: "end_call",
                      backgroundColor: Colors.red,
                      onPressed: () => _endCall(isRemoteEnd: false),
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    FloatingActionButton(
                      heroTag: "speaker",
                      backgroundColor:
                          _isSpeakerOn ? Colors.pinkAccent : Colors.white24,
                      onPressed: _toggleSpeaker,
                      child: Icon(
                          _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRippleCircle(double extraRadius) {
    double radius = 70 + extraRadius;
    double opacity = (1.0 - (extraRadius / 50)).clamp(0.0, 1.0);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.greenAccent.withOpacity(opacity),
          width: 2.5,
        ),
      ),
    );
  }
}