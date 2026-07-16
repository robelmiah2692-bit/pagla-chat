import 'package:pagla_chat/ludo_game/position.dart';

enum TokenType {
  green,
  yellow,
  blue,
  red
}

enum TokenState {
  initial,
  home,
  normal,
  safe,
  safeinpair
}

class Token {
  final int id;
  final TokenType type;
  Position tokenPosition;
  TokenState tokenState;
  
  // positionInPath ভেরিয়েবলটি সরাসরি এখানে ভ্যালু দিয়ে দেওয়া হয়েছে
  // অথবা আপনি চাইলে কনস্ট্রাক্টরে এটি নিতে পারেন।
  int positionInPath;

  Token(
    this.type, 
    this.tokenPosition, 
    this.tokenState, 
    this.id, 
    {this.positionInPath = 0} // ডিফল্ট ভ্যালু ০ দেওয়া হয়েছে
  );
}