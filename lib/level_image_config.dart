class LevelImageConfig {
  // ১. এক্টিভ লেভেলের জন্য লেভেল অনুযায়ী নির্দিষ্ট ইমেজের লিংক (Level 1 থেকে 50)
  static final Map<int, String> activeLevelImages = {
    1: 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/level_1.webp',
    
  };

  static String getActiveLevelImage(int level) {
    // সরাসরি লেভেল নম্বর চেক করে রিটার্ন করবে, ভুল হওয়ার কোনো সুযোগ নেই
    if (activeLevelImages.containsKey(level)) {
      return activeLevelImages[level]!;
    }
    // যদি কোনো লেভেলের লিংক দেওয়া না থাকে তবে ডিফল্ট বা কাছাকাছি লেভেল দেখাবে
    return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/level_1.webp';
  }

  // ২. গিফট লেভেলের জন্য লেভেল অনুযায়ী নির্দিষ্ট ইমেজের লিংক (Level 1 থেকে 50)
  static final Map<int, String> giftLevelImages = {
    1: 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/level_1.webp',
    
  };

  static String getGiftLevelImage(int level) {
    if (giftLevelImages.containsKey(level)) {
      return giftLevelImages[level]!;
    }
    return 'https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/activelavel/level_1.webp';
  }
}