import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/game_state.dart';
import 'package:pagla_chat/ludo_game/gameplay.dart';
import 'package:provider/provider.dart';
import 'package:pagla_chat/ludo_game/dice_model.dart';
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => GameState()),
          ChangeNotifierProvider(create: (context) => DiceModel()),
        ],
        child: MyHomePage(title: 'Ludo Home'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String roomId;
  final String title;

  MyHomePage({Key? key, required this.title, this.roomId = "42635"}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey keyBar = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        key: keyBar,
        title: Text(widget.title),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('ludo_rooms/${widget.roomId}/players').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<Map<String, dynamic>> users = [];
          
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
            
            data.forEach((uid, value) {
              // এখানে প্রিন্ট স্টেটমেন্টটি বসিয়েছি
              debugPrint("Checking DB User: ${value['name']}, Color in DB: ${value['color']}");

              // ডাটাবেসের কালার যদি না থাকে তবে ডিফল্ট হিসেবে 'green' ধরা হচ্ছে
              String assignedColor = value["color"]?.toString().toLowerCase() ?? "green";
              
              users.add({
                "name": value["name"] ?? "Player",
                "avatar": value["avatar"] ?? "",
                "color": assignedColor,
                "uid": uid
              });
            });
          }

          return GamePlay(
            keyBar,
            gameState,
            players: users,
          );
        },
      ),
    );
  }
}