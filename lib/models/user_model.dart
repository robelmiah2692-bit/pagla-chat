class UserModel {
  String name;
  String bio;
  int diamonds;
  int vipLevel;

  UserModel({
    required this.name,
    required this.bio,
    required this.diamonds,
    this.vipLevel = 0,
  });

  // ১ লাখ ডায়মন্ডে ১ লেভেল হিসাব
  void calculateVipLevel() {
    vipLevel = (diamonds / 100000).floor();
    if (vipLevel > 30) vipLevel = 30; // সর্বোচ্চ ৩০ লেভেল
  }
}
