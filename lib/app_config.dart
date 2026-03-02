class AppConfig {
  // ১. অ্যাপ ওনার (হৃদয় ভাই) শনাক্ত করার কোড
  static bool isHridoy(String id) {
    const String ownerId = "885522"; // আপনার দেওয়া কোড
    return id == ownerId;
  }

  // ২. ২০টি রিয়েল টাইপের অবতার পিকচার (১০ জন পুরুষ, ১০ জন মহিলা)
  static List<String> maleAvatars = [
    "https://i.pravatar.cc/150?u=m1",
    "https://i.pravatar.cc/150?u=m2",
    "https://i.pravatar.cc/150?u=m3",
    "https://i.pravatar.cc/150?u=m4",
    "https://i.pravatar.cc/150?u=m5",
    "https://i.pravatar.cc/150?u=m6",
    "https://i.pravatar.cc/150?u=m7",
    "https://i.pravatar.cc/150?u=m8",
    "https://i.pravatar.cc/150?u=m9",
    "https://i.pravatar.cc/150?u=m10",
  ];

  static List<String> femaleAvatars = [
    "https://i.pravatar.cc/150?u=f1",
    "https://i.pravatar.cc/150?u=f2",
    "https://i.pravatar.cc/150?u=f3",
    "https://i.pravatar.cc/150?u=f4",
    "https://i.pravatar.cc/150?u=f5",
    "https://i.pravatar.cc/150?u=f6",
    "https://i.pravatar.cc/150?u=f7",
    "https://i.pravatar.cc/150?u=f8",
    "https://i.pravatar.cc/150?u=f9",
    "https://i.pravatar.cc/150?u=f10",
  ];
}
