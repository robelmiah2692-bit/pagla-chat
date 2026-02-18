class UserModel {
  final String uID;
  final String roomID;
  final String name;
  // ... তোমার আগের অন্য সব ভেরিয়েবল

  UserModel({required this.uID, required this.roomID, required this.name});

  // ডাটাবেস থেকে ডাটা পড়ার জন্য
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uID: data['uID'] ?? '',
      roomID: data['roomID'] ?? '',
      name: data['name'] ?? '',
    );
  }
}
