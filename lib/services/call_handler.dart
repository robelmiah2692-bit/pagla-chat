import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'call_screen.dart';

class CallHandler {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static StreamSubscription<DocumentSnapshot>? _incomingCallSubscription;
  static BuildContext? _incomingDialogContext;

  // ১. কল করার সময় সিগন্যাল পাঠানো এবং গিটহ্যাব লিঙ্ক থেকে রিংটোন বাজানো
  static Future<void> makeCall({
    required BuildContext context,
    required String myId,
    required String myName,
    required String myPic,
    required String receiverId,
    required String receiverName,
    required String receiverPic,
    required String channelId,
  }) async {
    await _audioPlayer.play(
      UrlSource(
          'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/calling_ring.mp3'),
    );
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    await FirebaseFirestore.instance.collection('calls').doc(receiverId).set({
      'channelId': channelId,
      'callerId': myId,
      'callerName': myName,
      'callerPic': myPic,
      'receiverId': receiverId,
      'status': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: channelId,
            peerName: receiverName,
            peerPic: receiverPic,
            myName: myName,
            myPic: myPic,
            isCaller: true,
            myId: myId,
            targetId: receiverId,
          ),
        ),
      );
    }

    _audioPlayer.stop();
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(receiverId)
        .delete();
  }

  // ২. ইনকামিং কল লিসেন করার জন্য (সংশোধিত ও নিরাপদ)
  static void listenForIncomingCalls(BuildContext context, String myId) {
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(myId)
        .snapshots()
        .listen((snapshot) async {
      // যদি কল ডকুমেন্ট রিমুভ হয়ে যায় (কলার কল কেটে দেয়)
      if (!snapshot.exists) {
        await _audioPlayer.stop();
        if (_incomingDialogContext != null) {
          try {
            Navigator.pop(_incomingDialogContext!);
          } catch (e) {
            debugPrint("Error closing incoming dialog: $e");
          }
          _incomingDialogContext = null;
        }
        return;
      }

      var data = snapshot.data();
      if (data != null && data['status'] == 'calling') {
        String callerName = data['callerName'];
        String callerPic = data['callerPic'];
        String channelId = data['channelId'];
        String callerId = data['callerId'];

        await _audioPlayer.play(
          UrlSource(
              'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/incoming_ring.mp3'),
        );
        _audioPlayer.setReleaseMode(ReleaseMode.loop);

        if (context.mounted && _incomingDialogContext == null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              _incomingDialogContext = dialogContext;
              return AlertDialog(
                backgroundColor: const Color(0xFF1A1A2E),
                title: const Text("Incoming Call...",
                    style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(callerPic),
                    ),
                    const SizedBox(height: 15),
                    Text(callerName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  // কল রিজেক্ট বাটন
                  IconButton(
                    icon:
                        const Icon(Icons.call_end, color: Colors.red, size: 30),
                    onPressed: () async {
                      await _audioPlayer.stop();
                      _incomingDialogContext = null;
                      await FirebaseFirestore.instance
                          .collection('calls')
                          .doc(myId)
                          .delete();
                      Navigator.pop(dialogContext);
                    },
                  ),
                  // কল রিসিভ বাটন
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green, size: 30),
                    onPressed: () async {
                      await _audioPlayer.stop();
                      _incomingDialogContext = null;
                      Navigator.pop(dialogContext);

                      await FirebaseFirestore.instance
                          .collection('calls')
                          .doc(myId)
                          .update({'status': 'accepted'});

                      var myDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(myId)
                          .get();
                      String myName = myDoc.data()?['name'] ?? '';
                      String myPic = myDoc.data()?['profilePic'] ?? '';

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CallScreen(
                              channelId: channelId,
                              peerName: callerName,
                              peerPic: callerPic,
                              myName: myName,
                              myPic: myPic,
                              isCaller: false,
                              myId: myId,
                              targetId: callerId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ).then((_) {
            _incomingDialogContext = null;
          });
        }
      } else {
        // যদি স্ট্যাটাস calling ছাড়া অন্য কিছু হয়
        await _audioPlayer.stop();
        if (_incomingDialogContext != null) {
          try {
            Navigator.pop(_incomingDialogContext!);
          } catch (e) {}
          _incomingDialogContext = null;
        }
      }
    });
  }

  static Future<void> stopRinging() async {
    await _audioPlayer.stop();
  }
}