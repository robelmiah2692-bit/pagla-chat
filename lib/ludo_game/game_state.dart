import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pagla_chat/ludo_game/path.dart';
import 'package:pagla_chat/ludo_game/sound_service.dart';
import './position.dart';
import './token.dart';

class GameState with ChangeNotifier {
  TokenType currentPlayer = TokenType.green;
  int consecutiveSixCount = 0; 
  Timer? turnTimer; 

  // অ্যাক্টিভ প্লেয়ারদের কালার লিস্ট (ডিফল্টভাবে শুধু গ্রিন ও ইয়েলো রাখা হলো যাতে খালি ঘরে না ঘুরে, ফায়ারবেস থেকে আপডেট হয়ে যাবে)
  List<TokenType> activePlayerColors = [TokenType.green, TokenType.yellow]; 

  List<Token> gameTokens = List.generate(16, (index) => Token(TokenType.green, Position(0, 0), TokenState.initial, index));
  late List<Position> starPositions;
  List<Position> greenInitital = [];
  List<Position> yellowInitital = [];
  List<Position> blueInitital = [];
  List<Position> redInitital = [];

  GameState() {
    this.gameTokens = [
      Token(TokenType.green, Position(2, 2), TokenState.initial, 0),
      Token(TokenType.green, Position(2, 3), TokenState.initial, 1),
      Token(TokenType.green, Position(3, 2), TokenState.initial, 2),
      Token(TokenType.green, Position(3, 3), TokenState.initial, 3),
      Token(TokenType.yellow, Position(2, 11), TokenState.initial, 4),
      Token(TokenType.yellow, Position(2, 12), TokenState.initial, 5),
      Token(TokenType.yellow, Position(3, 11), TokenState.initial, 6),
      Token(TokenType.yellow, Position(3, 12), TokenState.initial, 7),
      Token(TokenType.blue, Position(11, 11), TokenState.initial, 8),
      Token(TokenType.blue, Position(11, 12), TokenState.initial, 9),
      Token(TokenType.blue, Position(12, 11), TokenState.initial, 10),
      Token(TokenType.blue, Position(12, 12), TokenState.initial, 11),
      Token(TokenType.red, Position(11, 2), TokenState.initial, 12),
      Token(TokenType.red, Position(11, 3), TokenState.initial, 13),
      Token(TokenType.red, Position(12, 2), TokenState.initial, 14),
      Token(TokenType.red, Position(12, 3), TokenState.initial, 15),
    ];
    this.starPositions = [
      Position(6, 1), Position(2, 6), Position(1, 8), Position(6, 12),
      Position(8, 13), Position(12, 8), Position(13, 6), Position(8, 2)
    ];
    startTurnTimer();
  }

  // ফায়ারবেস বা রুম থেকে জয়েন করা প্লেয়ারদের কালার সেট করার ফাংশন
  void setActivePlayers(List<Map<String, dynamic>> players) {
    if (players.isEmpty) return;
    
    List<TokenType> newActiveColors = [];
    for (var p in players) {
      String colorStr = (p['color'] ?? "").toString().toLowerCase().trim();
      if (colorStr == 'green') newActiveColors.add(TokenType.green);
      if (colorStr == 'yellow') newActiveColors.add(TokenType.yellow);
      if (colorStr == 'red') newActiveColors.add(TokenType.red);
      if (colorStr == 'blue') newActiveColors.add(TokenType.blue);
    }
    
    // যদি নতুন কালার লিস্ট পাওয়া যায়, তবে তা আপডেট করা হবে
    if (newActiveColors.isNotEmpty) {
      // লিস্ট পরিবর্তন হলে তবেই আপডেট ও নোটিফাই করবে
      bool isDifferent = activePlayerColors.length != newActiveColors.length ||
          !activePlayerColors.every((element) => newActiveColors.contains(element));

      if (isDifferent) {
        activePlayerColors = newActiveColors;
        // যদি বর্তমান প্লেয়ার নতুনভবে জয়েন করা প্লেয়ারদের লিস্টে না থাকে, তবে প্রথম প্লেয়ারকে চাল দেওয়া হবে
        if (!activePlayerColors.contains(currentPlayer)) {
          currentPlayer = activePlayerColors.first;
        }
        notifyListeners();
      }
    }
  }

  void startTurnTimer() {
    turnTimer?.cancel();
    turnTimer = Timer(Duration(seconds: 30), () {
      autoMoveToken();
    });
  }

  // মূল টার্ন পরিবর্তনের লজিক - শুধুমাত্র জয়েন করা প্লেয়ারদের ভেতর চাল আবর্তিত হবে
  void nextTurn() {
    consecutiveSixCount = 0;

    if (activePlayerColors.isNotEmpty) {
      int currentIndex = activePlayerColors.indexOf(currentPlayer);

      if (currentIndex != -1 && currentIndex < activePlayerColors.length - 1) {
        currentPlayer = activePlayerColors[currentIndex + 1];
      } else {
        currentPlayer = activePlayerColors.first;
      }
    } else {
      // ফলব্যাক লজিক
      if (currentPlayer == TokenType.green) currentPlayer = TokenType.yellow;
      else if (currentPlayer == TokenType.yellow) currentPlayer = TokenType.blue;
      else if (currentPlayer == TokenType.blue) currentPlayer = TokenType.red;
      else currentPlayer = TokenType.green;
    }

    startTurnTimer();
    notifyListeners();
  }
// ডাইস রোল হওয়ার পর ৬ বা অন্য সংখ্যা হ্যান্ডেল করার নিয়ম
  void handleDiceResult(int rolledValue) {
    if (rolledValue == 6) {
      consecutiveSixCount++;
      if (consecutiveSixCount >= 3) {
        debugPrint("টানা ৩ বার ৬ উঠেছে! চাল বাতিল এবং টার্ন পরিবর্তন হচ্ছে।");
        consecutiveSixCount = 0;
        nextTurn();
      } else {
        debugPrint("৬ উঠেছে! প্লেয়ার আবার ডাইস ঘোরাতে পারবে।");
        startTurnTimer();
      }
    } else {
      consecutiveSixCount = 0;
    }
    notifyListeners();
  }
  
  bool hasValidMoves(TokenType playerType, int diceValue) {
    List<Token> playerTokens = gameTokens.where((t) => t.type == playerType).toList();

    for (Token token in playerTokens) {
      // যদি গুটি হোম বা ইনিশিয়ালে থাকে, তবে শুধু ৬ উঠলেই চাল দেওয়া সম্ভব
      if (token.tokenState == TokenState.home) continue;
      
      if (token.tokenState == TokenState.initial) {
        if (diceValue == 6) return true;
        continue;
      }

      // যদি গুটি বোর্ডে চলমান থাকে, তবে দেখতে হবে চাল দিলে ৫৬ এর বেশি পার হয়ে যায় কি না
      int nextPathPos = token.positionInPath + diceValue;
      if (nextPathPos <= 56) {
        return true; // বৈধ চাল পাওয়া গেছে
      }
    }
    return false; // কোনো বৈধ চাল নেই
  }
  
  void moveToken(Token token, int steps) {
    if (token.type != currentPlayer) return;

    if (steps == 6) {
      consecutiveSixCount++;
      if (consecutiveSixCount >= 3) {
        consecutiveSixCount = 0;
        nextTurn();
        return;
      }
    } else {
      consecutiveSixCount = 0;
    }

    if (token.tokenState == TokenState.home) return;
    if (token.tokenState == TokenState.initial && steps != 6) return;

    if (token.tokenState == TokenState.initial && steps == 6) {
      SoundService.playTokenMoveSound();
      
      Position destination = _getPosition(token.type, 0);
      _updateInitalPositions(token);
      _updateBoardState(token, destination, 0);
      this.gameTokens[token.id].tokenPosition = destination;
      this.gameTokens[token.id].positionInPath = 0;
    } else if (token.tokenState != TokenState.initial) {
      int step = token.positionInPath + steps;
      if (step > 56) return;
      Position destination = _getPosition(token.type, step);
      Token? cutToken = _updateBoardState(token, destination, step);

      int duration = 0;
      for (int i = 1; i <= steps; i++) {
        duration += 500;
        Future.delayed(Duration(milliseconds: duration), () {
          int stepLoc = token.positionInPath + 1;
          this.gameTokens[token.id].tokenPosition = _getPosition(token.type, stepLoc);
          this.gameTokens[token.id].positionInPath = stepLoc;
          token.positionInPath = stepLoc;
          notifyListeners();
        });
      }

      if (cutToken != null) {
        Future.delayed(Duration(milliseconds: duration + 500), () {
          _cutToken(cutToken!);
          notifyListeners();
        });
      }
    }

    if (checkWin(token.type)) {
      showWinPopup(token.type);
    } else if (steps != 6) {
      nextTurn();
    } else {
      startTurnTimer();
    }
    notifyListeners();
  }

  bool checkWin(TokenType type) {
    return gameTokens.where((t) => t.type == type).every((t) => t.tokenState == TokenState.home);
  }

  void showWinPopup(TokenType winner) {
    print("Winner: $winner");
  }

  void autoMoveToken() {
    nextTurn();
  }

  Token? _updateBoardState(Token token, Position destination, int pathPosition) {
    if (this.starPositions.contains(destination)) {
      this.gameTokens[token.id].tokenState = TokenState.safe;
      return null;
    }
    List<Token> tokenAtDestination = this.gameTokens.where((tkn) =>
        tkn.tokenPosition.row == destination.row &&
        tkn.tokenPosition.column == destination.column).toList();

    if (tokenAtDestination.isEmpty) {
      this.gameTokens[token.id].tokenState = TokenState.normal;
      return null;
    }

    List<Token> tokenAtDestinationSameType = tokenAtDestination.where((tkn) => tkn.type == token.type).toList();
    if (tokenAtDestinationSameType.length == tokenAtDestination.length) {
      for (Token tkn in tokenAtDestinationSameType) {
        this.gameTokens[tkn.id].tokenState = TokenState.safeinpair;
      }
      this.gameTokens[token.id].tokenState = TokenState.safeinpair;
      return null;
    }

    Token? cutToken;
    for (Token tkn in tokenAtDestination) {
      if (tkn.type != token.type && tkn.tokenState != TokenState.safeinpair) {
        cutToken = tkn;
      }
    }
    this.gameTokens[token.id].tokenState = tokenAtDestinationSameType.isNotEmpty ? TokenState.safeinpair : TokenState.normal;
    return cutToken;
  }

  void _updateInitalPositions(Token tokentype) {
    // handled inside switch
  }

  void _updateInitalPositionsReal(Token token) {
    switch (token.type) {
      case TokenType.green: this.greenInitital.add(token.tokenPosition); break;
      case TokenType.yellow: this.yellowInitital.add(token.tokenPosition); break;
      case TokenType.blue: this.blueInitital.add(token.tokenPosition); break;
      case TokenType.red: this.redInitital.add(token.tokenPosition); break;
    }
  }

  void _cutToken(Token token) {
    switch (token.type) {
      case TokenType.green:
        this.gameTokens[token.id].tokenState = TokenState.initial;
        this.gameTokens[token.id].tokenPosition = this.greenInitital.first;
        this.greenInitital.removeAt(0);
        break;
      case TokenType.yellow:
        this.gameTokens[token.id].tokenState = TokenState.initial;
        this.gameTokens[token.id].tokenPosition = this.yellowInitital.first;
        this.yellowInitital.removeAt(0);
        break;
      case TokenType.blue:
        this.gameTokens[token.id].tokenState = TokenState.initial;
        this.gameTokens[token.id].tokenPosition = this.blueInitital.first;
        this.blueInitital.removeAt(0);
        break;
      case TokenType.red:
        this.gameTokens[token.id].tokenState = TokenState.initial;
        this.gameTokens[token.id].tokenPosition = this.redInitital.first;
        this.redInitital.removeAt(0);
        break;
    }
  }

  Position _getPosition(TokenType type, int step) {
    switch (type) {
      case TokenType.green: return Position(Path.greenPath[step][0], Path.greenPath[step][1]);
      case TokenType.yellow: return Position(Path.yellowPath[step][0], Path.yellowPath[step][1]);
      case TokenType.blue: return Position(Path.bluePath[step][0], Path.bluePath[step][1]);
      case TokenType.red: return Position(Path.redPath[step][0], Path.redPath[step][1]);
    }
  }

  void updateGameStateInFirebase(String roomId) {
    List<Map<String, dynamic>> tokenData = gameTokens.map((t) => {
      "id": t.id,
      "type": t.type.toString(),
      "row": t.tokenPosition.row,
      "column": t.tokenPosition.column,
      "state": t.tokenState.toString(),
      "pathPos": t.positionInPath,
    }).toList();

    FirebaseDatabase.instance.ref("ludo_rooms/$roomId/game_state").set({
      "tokens": tokenData,
      "currentPlayer": currentPlayer.toString(),
      "timestamp": ServerValue.timestamp,
    });
  }
}