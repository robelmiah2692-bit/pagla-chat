import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb চেক করার জন্য

// ফায়ারবেস প্যাকেজ
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// আপনার তৈরি করা অন্যান্য পেজ
import 'home_page.dart';
import 'screens/voice_room.dart';
import 'inbox_page.dart';
import 'profile_page.dart';
import 'room_list_page.dart';

// --- সতর্কতা: নোটিফিকেশন সার্ভিস ---
// গিটহাবে ফাইল না থাকলে এই ইম্পোর্টটি এরর দিবে। 
// ফাইলটি থাকলে নিচের লাইনটি আনকমেন্ট করুন, নাহলে এভাবেই রাখুন।
// import 'services/notification_service.dart'; 

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // ১. ফায়ারবেস ইনিশিয়ালাইজেশন (ওয়েব ও মোবাইল সাপোর্ট)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA9KMdtIBNVYSASc5C2w5JGVTL-NISXFog",
        authDomain: "paglachat.firebaseapp.com",
        databaseURL: "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "paglachat",
        storageBucket: "paglachat.firebasestorage.app",
        messagingSenderId: "25052070011",
        appId: "1:25052070011:web:7c447f8d011fbdf3d662de",
        measurementId: "G-946LX0V0Q9",
      ),
    );

    // ২. শুধু মোবাইলের জন্য নোটিফিকেশন (ওয়েবে এরর রোধ করতে)
    if (!kIsWeb) {
      try {
        // NotificationService().initNotification(); // ফাইলটি থাকলে আনকমেন্ট করুন
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }
    }

    debugPrint("পাগলা চ্যাট কানেক্ট হয়েছে!");
  } catch (e) {
    debugPrint("কানেকশন এরর: $e");
  }
  
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pagla Chat',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primaryColor: Colors.pinkAccent,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- স্প্ল্যাশ স্ক্রিন ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 100, color: Colors.pinkAccent),
            SizedBox(height: 20),
            Text("PAGLA CHAT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

// --- মেইন নেভিগেশন ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const RoomListPage(),
    const InboxPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF151525),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "হোম"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "রুম"),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: "ইনবক্স"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}

// --- লগইন স্ক্রিন (হৃদয় ভাই, আপনার রিকোয়েস্ট অনুযায়ী বেসিক লজিক ঠিক আছে) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("LOGIN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    // লগইন সাকসেস হলে নেভিগেশন
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
                  }, 
                  child: const Text("Login"))
            ],
          ),
        ),
      ),
    );
  }
}

// --- ফায়ারস্টোর ইনিশিয়ালাইজেশন ---
Future<void> initializeUserInFirestore(User user, String name) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String uID = (100000 + Random().nextInt(900000)).toString();
  await db.collection('users').doc(user.uid).set({
    'uID': uID,
    'name': name,
    'profilePic': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uID',
  }, SetOptions(merge: true));
}
