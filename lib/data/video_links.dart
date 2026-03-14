// ফাইল নাম: video_links.dart
class VideoLinks {
  // ডায়মন্ডের দাম অনুযায়ী ভিডিওর লিঙ্ক
  static const Map<int, String> giftVideos = {
    4770: "https://your-server.com/romantic_dragon.mp4",
    5000: "https://your-server.com/luxury_car.mp4",
    // নতুন গিফট আসলে শুধু এখানে নিচে একটি লাইন বাড়াবেন
  };

  // দাম দিয়ে লিঙ্ক খুঁজার সহজ ফাংশন
  static String? getLinkByPrice(int price) {
    return giftVideos[price];
  }
}
