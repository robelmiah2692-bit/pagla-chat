import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagla_chat/ludo_game/token.dart';
import './board.dart';
import './tokenp.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';

class GamePlay extends StatefulWidget {
  final GlobalKey keyBar;
  final GameState gameState;
  final List<Map<String, dynamic>> players; 
  final String roomId; 

  GamePlay(this.keyBar, this.gameState, {required this.players, required this.roomId});

  @override
  _GamePlayState createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> {
  bool boardBuild = false;
  final List<List<GlobalKey>> keyRefrences = _getGlobalKeys();

  String ownerId = "";
  List<String> adminList = [];
  String myNumericUserId = ""; 
  String authUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserCustomId();
    _listenRoomDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          boardBuild = true;
        });
      }
    });
  }

  void _fetchCurrentUserCustomId() async {
    if (authUid.isEmpty) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(authUid)
          .get();
      
      String fetchedId = "";

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        fetchedId = userData['uID']?.toString() ?? userData['userId']?.toString() ?? "";
      } 
      
      if (fetchedId.isEmpty) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection("users")
            .where('auth', isEqualTo: authUid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          querySnapshot = await FirebaseFirestore.instance
              .collection("users")
              .where('uid', isEqualTo: authUid)
              .limit(1)
              .get();
        }

        if (querySnapshot.docs.isNotEmpty) {
          Map<String, dynamic> userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          fetchedId = userData['uID']?.toString() ?? userData['userId']?.toString() ?? "";
        }
      }

      if (mounted && fetchedId.isNotEmpty) {
        setState(() {
          myNumericUserId = fetchedId;
        });
        debugPrint("GamePlay -> Found Custom uID: $myNumericUserId");
      }
    } catch (e) {
      debugPrint("Error fetching user custom ID: $e");
    }
  }

  // ফায়ারস্টোর থেকে রুমের ownerId এবং admins রিয়েল-টাইমে আনার ফাংশন
  void _listenRoomDetails() {
    FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId.toString())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        try {
          Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
          
          // মালিকের আইডি রিড করার আগের লজিক অপরিবর্তিত রাখা হয়েছে
          String fetchedOwnerId = roomData['ownerId']?.toString() ?? "";
          List<String> fetchedAdmins = [];

          // ১. প্রথমে সরাসরি রুট লেভেলের 'admins' ফিল্ড চেক করা (যেখান থেকে RoomFollowerSheet সেভ করে)
          if (roomData['admins'] != null) {
            var rawAdmins = roomData['admins'];
            if (rawAdmins is Map) {
              fetchedAdmins = rawAdmins.values.map((e) => e.toString()).toList();
            } else if (rawAdmins is List) {
              fetchedAdmins = rawAdmins.map((e) => e.toString()).toList();
            }
          } 
          
          // ২. যদি রুট লেভেলে না পাওয়া যায়, তবে পুরনো 'activeAdminAndOwner' স্ট্রাকচার চেক করা
          else if (roomData['activeAdminAndOwner'] != null) {
            var activeData = roomData['activeAdminAndOwner'];
            if (activeData is Map && activeData['admins'] != null) {
              var rawAdmins = activeData['admins'];
              if (rawAdmins is Map) {
                fetchedAdmins = rawAdmins.values.map((e) => e.toString()).toList();
              } else if (rawAdmins is List) {
                fetchedAdmins = rawAdmins.map((e) => e.toString()).toList();
              }
            }
          }

          setState(() {
            ownerId = fetchedOwnerId;
            adminList = fetchedAdmins;
          });

          debugPrint("Updated Firestore -> OwnerId: $ownerId, AdminList: $adminList");
        } catch (e) {
          debugPrint("Error parsing room details: $e");
        }
      }
    });
  }

  static List<List<GlobalKey>> _getGlobalKeys() {
    List<List<GlobalKey>> keysMain = [];
    for (int i = 0; i < 15; i++) {
      List<GlobalKey> keys = [];
      for (int j = 0; j < 15; j++) {
        keys.add(GlobalKey());
      }
      keysMain.add(keys);
    }
    return keysMain;
  }

  List<double> _getPosition(int row, int column) {
    if (widget.keyBar.currentContext == null) return [0, 0, 0, 0];
    final RenderBox renderBoxBar = widget.keyBar.currentContext!.findRenderObject() as RenderBox;
    final sizeBar = renderBoxBar.size;
    final cellBoxKey = keyRefrences[row][column];
    if (cellBoxKey.currentContext == null) return [0, 0, 0, 0];
    final RenderBox renderBoxCell = cellBoxKey.currentContext!.findRenderObject() as RenderBox;
    final positionCell = renderBoxCell.localToGlobal(Offset.zero);
    return [
      positionCell.dx + 1,
      (positionCell.dy - sizeBar.height + 1),
      renderBoxCell.size.width - 2,
      renderBoxCell.size.height - 2
    ];
  }

  List<Widget> _buildPlayerInfo() {
    return widget.players.map((player) {
      return Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(player['avatar'] ?? ''),
              radius: 15,
            ),
            Text(player['name'] ?? '', style: TextStyle(fontSize: 8, color: Colors.white)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    String activeCheckId = myNumericUserId.isNotEmpty ? myNumericUserId : authUid;

    return Stack(
      children: [
        Board(
          keyRefrences: keyRefrences, 
          players: widget.players, 
          roomId: widget.roomId,
          ownerId: ownerId,      
          adminList: adminList,  
          currentUserId: activeCheckId, 
          onCloseBoard: () {
            FirebaseDatabase.instance
                .ref("ludo_rooms/${widget.roomId}/lobby_status")
                .update({
              "showLobby": true,
              "isStarted": false,
            });
          },
        ),
        ...widget.gameState.gameTokens.map((token) => Tokenp(
          token: token,
          dimentions: _getPosition(token.tokenPosition.row, token.tokenPosition.column),
        )),
        Positioned(
          top: 50,
          left: 10,
          child: Row(children: _buildPlayerInfo()),
        ),
      ],
    );
  }
}