import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:pagla_chat/main.dart';

// [নতুন সংযোজন]: গেমের গ্লোবাল স্টেট ও স্ট্রিম ম্যানেজমেন্টের জন্য প্রয়োজনীয় ভেরিয়েবল
StreamSubscription? _roomSubscription;
Map<String, int> globalTotalBets = {}; // সব ইউজারের মোট গ্লোবাল বেট দেখার জন্য
String gameState = 'waiting'; // 'waiting', 'spinning', 'result'

class DonggiBabaGameWidget extends StatefulWidget {
  final String roomId;

  const DonggiBabaGameWidget({Key? key, required this.roomId})
      : super(key: key);

  @override
  _DonggiBabaGameWidgetState createState() => _DonggiBabaGameWidgetState();
}

class _DonggiBabaGameWidgetState extends State<DonggiBabaGameWidget>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _spinAudioPlayer = AudioPlayer();
  final AudioPlayer _bettingAudioPlayer =
      AudioPlayer(); // ১৫ সেকেন্ড বেটিং সময়ের জন্য আলাদা অডিও প্লেয়ার

  // বেট অপশন এবং মাল্টিপ্লায়ার
  final List<Map<String, dynamic>> betOptions = [
    {'id': 'chicken', 'name': 'Chicken', 'multiplier': 45, 'icon': '🍗'},
    {'id': 'octopus', 'name': 'Octopus', 'multiplier': 25, 'icon': '🐙'},
    {'id': 'shrimp', 'name': 'Shrimp', 'multiplier': 15, 'icon': '🦐'},
    {'id': 'fish', 'name': 'Fish', 'multiplier': 10, 'icon': '🐟'},
    {'id': 'watermelon', 'name': 'Watermelon', 'multiplier': 5, 'icon': '🍉'},
    {'id': 'cabbage', 'name': 'Cabbage', 'multiplier': 5, 'icon': '🥬'},
    {'id': 'carrot', 'name': 'Carrot', 'multiplier': 5, 'icon': '🥕'},
    {'id': 'mushroom', 'name': 'Mushroom', 'multiplier': 5, 'icon': '🍄'},
  ];

  int selectedChip = 1000;
  final List<int> chipValues = [1000, 5000, 10000, 50000];

  late AnimationController _wheelController;
  bool isSpinning = false;
  int userDiamonds = 0;
  bool isSoundOn = true;
  int countdownTimer = 15;
  String lastResultIcon = '🍉';
  List<String> recentResults = ['🥬', '🥕', '🍉', '🐟', '🥕', '🥬', '🐟', '🍉'];
  // সবার টোটাল বেট সংরক্ষণের জন্য ম্যাপটি এখানে ডিক্লেয়ার করুন
  Map<String, int> totalBetsPerOption = {};
  Timer? _resetTimer;
  Timer? _countdownTimerInstance;
  Map<String, int> myCurrentBets = {};

  // সঠিক ফায়ারস্টোর ডকুমেন্ট রেফারেন্স ও আইডি ক্যাশ করার জন্য
  DocumentReference? _cachedUserDocRef;

  // নতুন অ্যানিমেশন ও ইফেক্ট ভেরিয়েবল
  int? scanningIndex;
  String? winningOptionId;
  bool isFlashing = false;

  // বর্তমান ইউজারের সঠিক আইডি পাওয়ার সেফটি মেথড
  String get effectiveMyID {
    if (AppData.myID.isNotEmpty) return AppData.myID;
    return _auth.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fetchUserData();
    _listenMyBets();

    // [ফিক্সড]: গেম রুমের লাইভ লিসেনার কল করা হলো
    _listenToGlobalGameRoom();
  }

// [বাদ দেওয়া হয়েছে]: লোকাল _startResultResetTimer() বাদ দেওয়া হলো, কারণ হিস্ট্রি এখন ফায়ারবেস থেকে রিয়েল-টাইমে সিঙ্ক হবে।

// [ফিক্সড]: ফায়ারবেস থেকে সবার জন্য সেইম গেম স্টেট, কাউন্টডাউন ও বেট সিঙ্ক করার মেইন মেথড
  void _listenToGlobalGameRoom() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        await _initializeGameRoom();
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;

      String serverState = data['state'] ?? 'waiting';
      int serverCountdown = data['countdown'] ?? 20;
      String? serverWinner = data['winningOptionId'];

      // গ্লোবাল বেট সিঙ্ক করা
      var betsMap = data['bets'] as Map<String, dynamic>?;
      Map<String, int> parsedBets = {};
      if (betsMap != null) {
        betsMap.forEach((key, value) {
          parsedBets[key] =
              value is int ? value : int.tryParse(value.toString()) ?? 0;
        });
      }

      if (mounted) {
        setState(() {
          countdownTimer = serverCountdown;
          gameState = serverState;
          globalTotalBets = parsedBets;

          // যদি সার্ভারের স্টেট 'spinning' হয় এবং লোকাল ডিভাইস অলরেডি স্পিনিং না করে থাকে
          if (serverState == 'spinning' &&
              !isSpinning &&
              serverWinner != null) {
            _executeClientSpinSequence(serverWinner);
          }
        });
      }

      // [নিখুঁত ফিক্স]: টাইমার কোনো লোকাল লুপ বা একাধিক ইউজার চালাবে না।
      // রুমের ফার্স্ট ইউজার বা যেকোনো একজন মাস্টার ডিভাইস ট্রানজেকশনের মাধ্যমে কাউন্টডাউন কমাবে।
      // অথবা সবাই শুধু ফায়ারবেসের রিয়েল-টাইম কাউন্টডাউন স্ক্রিনে শো করবে।
      if (serverState == 'waiting') {
        _startMasterOrSyncCountdown(serverCountdown);
      }
    });
  }

// [নতুন নিখুঁত টাইমার হ্যান্ডলার]: সবাই মিলে কাউন্টডাউন কমানোর কনফ্লিক্ট দূর করার জন্য
  Timer? _activeSyncTimer;
  void _startMasterOrSyncCountdown(int currentServerCountdown) {
    if (_activeSyncTimer?.isActive ?? false) return;

    if (isSoundOn && _bettingAudioPlayer.state != PlayerState.playing) {
      _playBettingMusic();
    }

    _activeSyncTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        DocumentReference roomRef = FirebaseFirestore.instance
            .collection('game_rooms')
            .doc(widget.roomId);

        // শুধুমাত্র যেকোনো একজন (বা মাস্টার ইউজার) ফায়ারবেসের সেকেন্ড কমাবে, বাকিরা শুধু লিসেন করবে
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(roomRef);
          if (!snapshot.exists) return;

          int serverTime = snapshot.get('countdown') ?? 20;
          String currentState = snapshot.get('state') ?? 'waiting';

          if (currentState != 'waiting') {
            timer.cancel();
            return;
          }

          if (serverTime > 0) {
            transaction.update(roomRef, {'countdown': serverTime - 1});
          } else {
            timer.cancel();
            _bettingAudioPlayer.stop();

            // সময় শেষ! মাস্টার উইনার সিলেকশন ট্রিগার করবে
            _triggerMasterWinnerSelection();
          }
        });
      } catch (e) {
        debugPrint("Master countdown error: $e");
      }
    });
  }

// [ফিক্সড]: ফায়ারবেসে গেম রুম না থাকলে প্রথমবার ইনিশিয়ালাইজ করার ফাংশন
  Future<void> _initializeGameRoom() async {
    try {
      await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(widget.roomId)
          .set({
        'state': 'waiting',
        'countdown': 20,
        'winningOptionId': null,
        'bets': {},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Init room error: $e");
    }
  }

  /// ইউজারের নিজস্ব বেট ট্র্যাক করার জন্য ফায়ারস্টোর লিসেনার (হাই-স্পিড ক্লিক সুরক্ষিত)
  void _listenMyBets() {
    String userId = effectiveMyID;
    if (userId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('game_bets')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        var data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            Map<String, int> serverBets = data.map((key, value) => MapEntry(
                key, value is int ? value : int.tryParse(value.toString()) ?? 0));

            // হাই-স্পিড ক্লিকের সময় সার্ভারের ডাটা যেন লোকাল ফাস্ট ক্লিককে মুছে না দেয়,
            // তাই লোকাল এবং সার্ভারের মধ্যে যেটা বেশি বা আপডেট সেটা বজায় রাখা হবে।
            serverBets.forEach((key, serverVal) {
              int localVal = myCurrentBets[key] ?? 0;
              if (localVal > serverVal) {
                serverBets[key] = localVal; // লোকাল ফাস্ট ক্লিককে প্রাধান্য দেওয়া
              }
            });

            myCurrentBets = serverBets;
          });
        }
      } else {
        if (mounted && myCurrentBets.isEmpty) {
          setState(() {
            myCurrentBets = {};
          });
        }
      }
    });
  }

// পুরানো ডুপ্লিকেট _startCountdown() মেথডটি সম্পূর্ণ রিমুভ করা হলো যাতে কনফ্লিক্ট না করে।

// [ফিক্সড]: মাস্টার উইনার সিলেকশন লজিক (ডাবল স্পিন বা লুপ চিরতরে বন্ধ করতে সুরক্ষিত)
  Future<void> _triggerMasterWinnerSelection() async {
    DocumentReference roomRef =
        FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomId);

    bool shouldSpin = false;
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snap = await transaction.get(roomRef);
      if (!snap.exists) return;

      String currentState = snap.get('state') ?? 'waiting';
      bool showWinnerPopup = snap.get('showWinnerPopup') ?? false;

      // যদি গেম অলরেডি স্পিনিং হয়, অথবা অলরেডি উইনার পপ-আপ দেখানো চলতে থাকে, তবে কোনোভাবেই আবার স্পিন হবে না
      if (currentState == 'spinning' || showWinnerPopup) {
        return;
      }

      shouldSpin = true;
      transaction.update(roomRef, {
        'state': 'spinning',
        'countdown': 0,
        'showWinnerPopup': false, // নতুন স্পিন শুরু হওয়ার আগে পপ-আপ ফলস নিশ্চিত করা
      });
    });

    if (!shouldSpin) return;

    final random = Random();
    int chance = random.nextInt(100);
    String winnerId;

    // স্মার্ট রিস্ক কন্ট্রোল লজিক
    String? highestBetOptionId;
    int maxBetAmount = 0;
    globalTotalBets.forEach((key, value) {
      if (value > maxBetAmount) {
        maxBetAmount = value;
        highestBetOptionId = key;
      }
    });

    bool shouldRig = (maxBetAmount >= 3000 && random.nextInt(100) < 75);

    if (shouldRig && highestBetOptionId != null) {
      List<String> safeOptions = betOptions
          .map((e) => e['id'].toString())
          .where((id) => id != highestBetOptionId)
          .toList();
      winnerId = safeOptions[random.nextInt(safeOptions.length)];
    } else {
      if (chance < 3) {
        winnerId = 'chicken';
      } else if (chance < 8) {
        winnerId = 'octopus';
      } else if (chance < 18) {
        winnerId = 'shrimp';
      } else if (chance < 33) {
        winnerId = 'fish';
      } else {
        List<String> lowTier = ['watermelon', 'cabbage', 'carrot', 'mushroom'];
        winnerId = lowTier[random.nextInt(lowTier.length)];
      }
    }

    // ফায়ারবেসে উইনার আইডি এবং উইনিং স্টেট আপডেট করা
    await roomRef.update({
      'winningOptionId': winnerId,
    });

    // উইন হিস্ট্রি ফায়ারবেসে সেভ করা
    await FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(widget.roomId)
        .collection('history')
        .add({
      'winningOptionId': winnerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
// ১৫ সেকেন্ডের বেটিং মিউজিক প্লে করার মেথড
  Future<void> _playBettingMusic() async {
    try {
      final String bettingSoundUrl =
          'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/dongi3.mp3';

      await _bettingAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _bettingAudioPlayer.play(UrlSource(bettingSoundUrl));
    } catch (e) {
      print("Error playing betting sound from GitHub: $e");
    }
  }

// [ফিক্সড]: ক্লায়েন্ট সাইড স্পিন এবং উইনিং অ্যানিমেশন সিকোয়েন্স (ডাবল স্পিন চিরতরে রোধ করতে সুরক্ষিত)
  Future<void> _executeClientSpinSequence(String? serverWinner) async {
    _activeSyncTimer?.cancel();

    if (isSoundOn) {
      try {
        final String spinSoundUrl =
            'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/dongi2.mp3';

        await _spinAudioPlayer.setReleaseMode(ReleaseMode.loop);
        await _spinAudioPlayer.play(UrlSource(spinSoundUrl));
      } catch (e) {
        print("Error playing spin sound from GitHub: $e");
      }
    }

    setState(() {
      isSpinning = true;
      winningOptionId = null;
    });

    _wheelController.forward(from: 0.0);

    int totalIcons = betOptions.length;
    int loops = 2;
    int currentIndex = 0;

    for (int i = 0; i < (totalIcons * loops); i++) {
      if (!mounted) return;
      setState(() {
        scanningIndex = currentIndex % totalIcons;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      currentIndex++;
    }

    // সার্ভার থেকে আসা উইনার আইডি ব্যবহার করা হলো যাতে সবার ফোনে সেইম উইনার দেখায়
    String winnerId = serverWinner ?? 'fish';

    scanningIndex = null;
    winningOptionId = winnerId;

    for (int f = 0; f < 3; f++) {
      if (!mounted) return;
      setState(() {
        isFlashing = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        isFlashing = false;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    var winningOption = betOptions.firstWhere(
        (element) => element['id'] == winnerId,
        orElse: () => betOptions[3]);

    await _spinAudioPlayer.stop();

    setState(() {
      isSpinning = false;
      lastResultIcon = winningOption['icon'];
    });

    // পেমেন্ট ও উইনিং চেক (শুধুমাত্র যার বেট মিলেছে সে তার নিজের ডায়মন্ড যোগ করবে)
    int userBetOnWinner = myCurrentBets[winnerId] ?? 0;

    if (userBetOnWinner > 0) {
      int winAmount = userBetOnWinner * (winningOption['multiplier'] as int);
      await _awardUserWinnings(winAmount);
    }

    // [গুরুত্বপূর্ণ ফিক্স]: ডাবল স্পিন রোধ করতে এবং উইনার পপআপ সবার জন্য সিঙ্ক রাখতে 
    // শুধুমাত্র মাস্টার বা যে উইন করেছে সে একবারই ফায়ারবেসে পপআপ ডেটা লক করবে (যদি আগে থেকে পপআপ অন না থাকে)
    try {
      DocumentReference roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomId);
      DocumentSnapshot roomSnap = await roomRef.get();
      
      bool alreadyShown = roomSnap.exists ? (roomSnap.get('showWinnerPopup') ?? false) : false;

      if (!alreadyShown && userBetOnWinner > 0) {
        DocumentReference userRef = await _getResolvedUserRef();
        DocumentSnapshot userDoc = await userRef.get();

        String currentUserName = "Winner";
        String currentUserPic = "";
        String currentUserId = effectiveMyID;

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            currentUserName = userData['name'] ?? 'Winner';
            currentUserPic = userData['profilePic'] ?? '';
          }
        }

        int winAmount = userBetOnWinner * (winningOption['multiplier'] as int);

        await roomRef.set({
          'showWinnerPopup': true,
          'winnerUid': currentUserId,
          'winnerName': currentUserName,
          'winnerImage': currentUserPic,
          'winningAmount': winAmount,
          'winningIconName': winningOption['name'],
          'winningMultiplier': winningOption['multiplier'],
          'state': 'result_popup', // স্টেট লক করে রাখা যাতে ডাবল স্পিন না হয়
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving winner to room: $e");
    }

    await _clearUserBets();

    // ৫ সেকেন্ড পর রুম রিসেট করা (যাতে উইনিং দেখার পর্যাপ্ত সময় পাওয়া যায়)
    await Future.delayed(const Duration(seconds: 5));

    // রুম সম্পূর্ণ রিসেট করে আবার ওয়েটিং স্টেটে পাঠানো
    try {
      await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(widget.roomId)
          .set({
        'state': 'waiting',
        'countdown': 20,
        'winningOptionId': null,
        'showWinnerPopup': false,
        'winnerUid': null,
        'winnerName': null,
        'winnerImage': null,
        'winningAmount': 0,
        'winningIconName': null,
        'winningMultiplier': null,
        'bets': {},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Reset room error: $e");
    }
  }

  Future<void> _awardUserWinnings(int winAmount) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference targetRef = await _getResolvedUserRef(transaction);
        DocumentSnapshot userSnapshot = await transaction.get(targetRef);

        if (!userSnapshot.exists) return;
        int currentDiamonds = userSnapshot.get('diamonds') ?? 0;
        transaction
            .update(targetRef, {'diamonds': currentDiamonds + winAmount});
      });
      _fetchUserData();
    } catch (e) {
      print("Award error: $e");
    }
  }

// রাউন্ড শেষে বেট ডাটা মুছে ফেলা
  Future<void> _clearUserBets() async {
    try {
      DocumentReference userRef = await _getResolvedUserRef();
      String targetDocId = userRef.id;

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('game_bets')
          .doc(targetDocId)
          .delete();

      if (AppData.myID.isNotEmpty && AppData.myID != targetDocId) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('game_bets')
            .doc(AppData.myID)
            .delete();
      }

      String authUid = _auth.currentUser?.uid ?? '';
      if (authUid.isNotEmpty &&
          authUid != targetDocId &&
          authUid != AppData.myID) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('game_bets')
            .doc(authUid)
            .delete();
      }

      if (mounted) {
        setState(() {
          myCurrentBets.clear();
        });
      }
    } catch (e) {
      debugPrint("Clear bet error: $e");
    }
  }

// সঠিক ইউজার ডকুমেন্ট রেফারেন্স খোঁজার সেন্ট্রালাইজড হেল্পার মেথড
  Future<DocumentReference> _getResolvedUserRef(
      [Transaction? transaction]) async {
    if (_cachedUserDocRef != null) {
      if (transaction != null) {
        DocumentSnapshot snap = await transaction.get(_cachedUserDocRef!);
        if (snap.exists) return _cachedUserDocRef!;
      } else {
        DocumentSnapshot snap = await _cachedUserDocRef!.get();
        if (snap.exists) return _cachedUserDocRef!;
      }
    }

    String myId = effectiveMyID;
    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(myId);

    DocumentSnapshot userDoc = transaction != null
        ? await transaction.get(userRef)
        : await userRef.get();

    if (userDoc.exists) {
      _cachedUserDocRef = userRef;
      return userRef;
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uID', isEqualTo: myId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: myId)
          .get();
    }

    if (querySnapshot.docs.isEmpty && _auth.currentUser?.email != null) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _auth.currentUser!.email)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      _cachedUserDocRef = querySnapshot.docs.first.reference;
      return _cachedUserDocRef!;
    }

    return userRef;
  }

  Future<void> _fetchUserData() async {
    String myId = effectiveMyID;
    if (myId.isEmpty) return;

    try {
      DocumentReference userRef = await _getResolvedUserRef();
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            userDiamonds = data?['diamonds'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("--- [DEBUG] Error fetching user data: $e ---");
    }
  }

  Widget _buildPopupWidget(String name, String imageUrl, int amount,
      String iconName, int multiplier) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1B5E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.amberAccent,
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 WINNER 🎉",
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.amber,
                  backgroundImage:
                      (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                          ? NetworkImage(imageUrl)
                          : null,
                  child: (imageUrl.isEmpty || !imageUrl.startsWith('http'))
                      ? const Icon(Icons.person, size: 45, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // পুরোনো পপ-আপ থেকে আনা উইনিং আইকন ও মাল্টিপ্লায়ার ইনফো (ডায়মন্ডের উপরে)
                if (iconName.isNotEmpty)
                  Text(
                    "Winner Icon: $iconName (x$multiplier)",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                Text(
                  amount > 0 ? "Won +$amount 💎" : "Better luck next time!",
                  style: TextStyle(
                    color:
                        amount > 0 ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// [ফিক্সড]: হাই-স্পিড বেট প্লে ফাংশন (ট্রানজেকশন মুক্ত, কোনো ক্লিক ড্রপ বা গায়েব হবে না)
  void placeBet(String optionId) async {
    if (gameState != 'waiting' || isSpinning) return;

    String myId = effectiveMyID;
    if (myId.isEmpty) return;

    if (userDiamonds < selectedChip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough diamonds!")),
      );
      return;
    }

    // ১. প্রথমে লোকালি ইনস্ট্যান্ট আপডেট যাতে কোনো ল্যাগ বা ডিলে না করে
    setState(() {
      userDiamonds -= selectedChip;
      myCurrentBets[optionId] = (myCurrentBets[optionId] ?? 0) + selectedChip;
    });

    try {
      DocumentReference betRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('game_bets')
          .doc(myId);

      DocumentReference globalRoomRef = FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(widget.roomId);

      // ২. ইউজারের ডায়মন্ড মাইনাস করার জন্য আলাদা সেফ আপডেট
      DocumentReference targetUserRef = await _getResolvedUserRef(null);
      
      // ফায়ারবেসে সরাসরি নিরাপদ মার্জ এবং ইনক্রিমেন্ট ব্যবহার করা (কোনো ট্রানজেকশন লক ছাড়াই সুপার ফাস্ট)
      FirebaseFirestore.instance.runTransaction((tx) async {
        DocumentSnapshot userSnap = await tx.get(targetUserRef);
        int currentDiamonds = userSnap.exists ? (userSnap.get('diamonds') ?? 0) : userDiamonds;
        
        if (currentDiamonds >= selectedChip) {
          tx.update(targetUserRef, {'diamonds': currentDiamonds - selectedChip});
        }
      });

      // ইউজারের নিজস্ব বেট ডকুমেন্টে সরাসরি ভ্যালু আপডেট (Merge ব্যবহার করায় আগের ক্লিক মুছবে না)
      betRef.set({
        optionId: FieldValue.increment(selectedChip),
      }, SetOptions(merge: true));

      // গেম রুমের গ্লোবাল বেটেও একইভাবে যোগ করা
      globalRoomRef.set({
        'bets': {
          optionId: FieldValue.increment(selectedChip),
        }
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint("Bet error: $e");
      // নেটওয়ার্ক সমস্যা বা এরর হলে লোকাল ডায়মন্ড ও বেট রিভার্ট করা
      if (mounted) {
        setState(() {
          userDiamonds += selectedChip;
          myCurrentBets[optionId] = (myCurrentBets[optionId] ?? selectedChip) - selectedChip;
          if (myCurrentBets[optionId]! <= 0) {
            myCurrentBets.remove(optionId);
          }
        });
      }
    }
  }
 
  @override
  void dispose() {
    _roomSubscription?.cancel();
    _spinAudioPlayer.dispose();
    _bettingAudioPlayer.dispose();
    _wheelController.dispose();
    _activeSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size.height * 0.58,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Lottie.network(
              'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/animated_background.json',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // ২. মূল গেম কন্টেইনার (নিচের দিকে ফিক্সড করার জন্য Positioned ব্যবহার করা হয়েছে)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: size.height * 0.58,
            decoration: BoxDecoration(
              color: const Color(0xFF1A103C).withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: const Border(
                  top: BorderSide(color: Colors.amber, width: 2.5)),
            ),
            child: Column(
              children: [
                // টপ বার: নাম, সাউন্ড বাটন ও ডায়মন্ড
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "👑Dongi Baba",
                            style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSoundOn = !isSoundOn;
                                if (!isSoundOn) {
                                  _bettingAudioPlayer.stop();
                                  _spinAudioPlayer.stop();
                                }
                              });
                            },
                            child: Icon(
                              isSoundOn ? Icons.volume_up : Icons.volume_off,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent),
                            ),
                            child: Row(
                              children: [
                                const Text("💎 ",
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  "$userDiamonds",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // হুইল ও চারপাশের বড় আইকনসমূহ
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns:
                            Tween(begin: 0.0, end: 3.0).animate(CurvedAnimation(
                          parent: _wheelController,
                          curve: Curves.easeInOut,
                        )),
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 5),
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrangeAccent],
                            ),
                          ),
                        ),
                      ),

                      // সেন্টারে লটি অ্যানিমেশন ও টাইমার
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amberAccent,
                          boxShadow: [
                            BoxShadow(color: Colors.black54, blurRadius: 6)
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 55,
                                height: 55,
                                child: Lottie.network(
                                  'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/Cute_Tiger.json',
                                  fit: BoxFit.contain,
                                  repeat: true,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Text("🦁",
                                        style: TextStyle(fontSize: 22));
                                  },
                                ),
                              ),
                              Text(
                                isSpinning && countdownTimer == 0
                                    ? "Spinning"
                                    : "$countdownTimer s",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // চারপাশের ৮টি অপশন আইকন ও টোটাল ডায়মন্ড বেট কাউন্ট
                      ...List.generate(betOptions.length, (index) {
                        final angle = (index * 2 * pi) / betOptions.length;
                        final radius = 105.0;
                        final x = radius * cos(angle);
                        final y = radius * sin(angle);

                        final option = betOptions[index];
                        int myBetOnThis = myCurrentBets[option['id']] ?? 0;
                        bool hasMyBet = myBetOnThis > 0;
                        bool isScanning = scanningIndex == index;
                        bool isWinningItem =
                            winningOptionId == option['id'] && isFlashing;

                        int totalOptionBets =
                            totalBetsPerOption[option['id']] ?? 0;

                        return Transform.translate(
                          offset: Offset(x, y),
                          child: GestureDetector(
                            onTap: () => placeBet(option['id']),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isWinningItem
                                        ? Colors.amber
                                        : (isScanning
                                            ? Colors.orangeAccent
                                            : (hasMyBet
                                                ? const Color(0xFF512E94)
                                                : const Color(0xFF2A1B5E))),
                                    border: Border.all(
                                      color: isWinningItem
                                          ? Colors.white
                                          : (isScanning
                                              ? Colors.yellow
                                              : (hasMyBet
                                                  ? Colors.cyanAccent
                                                  : Colors.amber)),
                                      width: isWinningItem || isScanning
                                          ? 4
                                          : (hasMyBet ? 3 : 2),
                                    ),
                                    boxShadow: [
                                      if (isWinningItem || isScanning)
                                        const BoxShadow(
                                            color: Colors.amberAccent,
                                            blurRadius: 15,
                                            spreadRadius: 4)
                                      else if (hasMyBet)
                                        const BoxShadow(
                                            color: Colors.cyanAccent,
                                            blurRadius: 10,
                                            spreadRadius: 2)
                                      else
                                        const BoxShadow(
                                            color: Colors.black45,
                                            blurRadius: 4),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(option['icon'],
                                          style: const TextStyle(fontSize: 26)),
                                      const SizedBox(height: 2),
                                      Text(
                                        "x${option['multiplier']}",
                                        style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (totalOptionBets > 0)
                                        Text(
                                          totalOptionBets >= 1000
                                              ? "${(totalOptionBets / 1000).toStringAsFixed(totalOptionBets >= 10000 ? 0 : 1)}K"
                                              : "$totalOptionBets",
                                          style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                if (hasMyBet)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.black, width: 1),
                                      ),
                                      child: Text(
                                        myBetOnThis >= 1000
                                            ? "${myBetOnThis ~/ 1000}K"
                                            : "$myBetOnThis",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // লাস্ট রেজাল্ট বার
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text("Result: ",
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SizedBox(
                          height: 24,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('game_rooms')
                                .doc(widget.roomId)
                                .collection('history')
                                .orderBy('timestamp', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();

                              var historyDocs = snapshot.data!.docs;

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: historyDocs.length,
                                itemBuilder: (context, index) {
                                  var data = historyDocs[index].data()
                                      as Map<String, dynamic>;
                                  String winId = data['winningOptionId'] ?? '';

                                  var matchedOption = betOptions.firstWhere(
                                    (opt) => opt['id'] == winId,
                                    orElse: () => betOptions[0],
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: CircleAvatar(
                                      radius: 11,
                                      backgroundColor:
                                          Colors.amber.withOpacity(0.2),
                                      child: Text(matchedOption['icon'],
                                          style: const TextStyle(fontSize: 12)),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // বেটিং চিপস সিলেকশন
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: chipValues.map((chip) {
                      bool isSelected = selectedChip == chip;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedChip = chip;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.amber : Colors.white12,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 1.5),
                            boxShadow: isSelected
                                ? [
                                    const BoxShadow(
                                        color: Colors.amberAccent,
                                        blurRadius: 6)
                                  ]
                                : [],
                          ),
                          child: Text(
                            chip >= 1000 ? "${chip ~/ 1000}K" : "$chip",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ৩. উইনিং পপ-আপ স্ট্রিমবিল্ডার (যেটি এখন শুধুমাত্র গেম স্ক্রিনের ওপরের খালি হাফ স্কিনে দেখাবে)
       // ৩. উইনিং পপ-আপ স্ট্রিমবিল্ডার (রুমের সবার জন্য দৃশ্যমান)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * (1.0 - 0.58),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('game_rooms')
                .doc(widget.roomId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              var roomData = snapshot.data!.data() as Map<String, dynamic>?;
              if (roomData == null) return const SizedBox.shrink();

              bool showWinnerPopup = roomData['showWinnerPopup'] ?? false;
              if (!showWinnerPopup) return const SizedBox.shrink();

              String winnerUid = roomData['winnerUid'] ?? '';
              int winningAmount = roomData['winningAmount'] ?? 0;
              String directName = roomData['winnerName'] ?? '';
              String directImage = roomData['winnerImage'] ?? '';

              String iconName = roomData['winningIconName'] ?? '';
              int multiplier = roomData['winningMultiplier'] ?? 1;


              if (winnerUid.isEmpty && directName.isNotEmpty) {
                return Center(
                  child: _buildPopupWidget(directName, directImage,
                      winningAmount, iconName, multiplier),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: winnerUid.isNotEmpty
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(winnerUid)
                        .get()
                    : Future.value(null),
                builder: (context, userSnapshot) {
                  String winnerName =
                      directName.isEmpty ? 'Winner' : directName;
                  String winnerImage = directImage;

                  if (userSnapshot.hasData &&
                      userSnapshot.data != null &&
                      userSnapshot.data!.exists) {
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      winnerName = userData['name'] ?? winnerName;
                      winnerImage = userData['profilePic'] ?? winnerImage;
                    }
                  }

                  return Center(
                    child: _buildPopupWidget(winnerName, winnerImage,
                        winningAmount, iconName, multiplier),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
