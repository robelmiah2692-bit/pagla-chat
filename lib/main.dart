import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // এইটা মিসিং আছে
import 'services/notification_service.dart'; // এইটাও চেক করুন
// ফায়ারবেস প্যাকেজ
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // নতুন যোগ করা হয়েছে

// আপনার তৈরি করা অন্যান্য পেজগুলো
import 'home_page.dart';
import 'screens/voice_room.dart';
import 'inbox_page.dart';
import 'profile_page.dart';
import 'room_list_page.dart';
import 'services/notification_service.dart'; // নোটিফিকেশন সার্ভিস ইম্পোর্ট

// ১. ব্যাকগ্রাউন্ড নোটিফিকেশন হ্যান্ডেলার (গ্লোবাল থাকতে হবে)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🔥 আপনার অরিজিনাল ফায়ারবেস কনফিগ (ওয়েব অপশন সহ)
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

    // ২. নোটিফিকেশন সার্ভিস শুরু করা
    NotificationService().initNotification();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print("পাগলা চ্যাট সব ফিচার সহ কানেক্ট হয়েছে!");
  } catch (e) {
    print("কানেকশন এরর: $e");
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

// --- ১. স্প্ল্যাশ স্ক্রিন (আপনার অরিজিনাল কোড) ---
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
        // ৩. হৃদয় ভাইকে শনাক্ত করার বিশেষ কোড এখানেও কাজ করবে
        if (user.displayName == "Hridoy" || user.email == "admin@pagla.com") {
           print("স্বাগতম হৃদয় ভাই!");
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.調, size: 100, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            const Text("PAGLA CHAT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.pinkAccent),
          ],
        ),
      ),
    );
  }
}

// --- ২. লগইন স্ক্রিন (আপনার অরিজিনাল কোড) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _signIn() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await initializeUserInFirestore(user, user.email?.split('@')[0] ?? "New User");
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("এরর: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PAGLA CHAT LOGIN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
            const SizedBox(height: 30),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "ইমেইল", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "পাসওয়ার্ড", border: OutlineInputBorder())),
            const SizedBox(height: 25),
            isLoading ? const CircularProgressIndicator() : ElevatedButton(
              onPressed: _signIn,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
              child: const Text("লগইন"),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ৩. মেইন নেভিগেশন (আপনার অরিজিনাল কোড + রিয়েল টাইম নোটিফিকেশন লিসেনার) ---
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
  void initState() {
    super.initState();
    // ৪. অ্যাপ খোলা থাকা অবস্থায় নোটিফিকেশন দেখানোর জন্য লিসেনার
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      NotificationService.display(message);
    });
  }

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

// --- ৪. ফায়ারস্টোর ইউজার ডাটা (আপনার র্যান্ডম আইডি ও অবতার লজিক) ---
Future<void> initializeUserInFirestore(User user, String name) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentSnapshot userDoc = await db.collection('users').doc(user.uid).get();

  if (!userDoc.exists) {
    String uID = (100000 + Random().nextInt(900000)).toString();
    String rID = (100000 + Random().nextInt(900000)).toString();

    await db.collection('users').doc(user.uid).set({
      'uID': uID,
      'roomID': rID,
      'name': name,
      'diamonds': 0, // নতুন ফিচার সেভ রাখার জন্য যোগ করা হলো
      'profilePic': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uID',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("নতুন প্রোফাইল তৈরি হয়েছে!");
  }
}
