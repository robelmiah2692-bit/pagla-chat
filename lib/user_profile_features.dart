import 'package:flutter/material.dart';
import 'visitors_screen.dart';
import 'my_posts_screen.dart';
import 'vip_benefits_screen.dart';
import 'games_screen.dart'; // নতুন ফাইলটি ইমপোর্ট করলাম

class UserProfileFeatures {
  
  static void openVisitors(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const VisitorsScreen()));
  }

  static void openMyPosts(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPostsScreen()));
  }

  static void openVIP(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const VIPBenefitsScreen()));
  }

  static void openGames(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const GamesScreen()));
  }
}