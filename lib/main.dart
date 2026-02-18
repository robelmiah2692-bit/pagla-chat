import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // ফায়ারবেস ইমপোর্ট
import 'package:firebase_auth/firebase_auth.dart'; // লগইন ইমপোর্ট
// আপনার তৈরি করা অন্যান্য পেজগুলো ইমপোর্ট করুন
import 'home_page.dart';
import 'voice_room.dart';
import 'inbox_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // শুধু Firebase.initializeApp(); দিলে হবে না, 
    // নিচের এই ডাটাগুলো মেনুয়ালি বসাতে হবে:
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAkEB8dB2vSncv3BpNZng7W_0e6N7dqNmI",
        appId: "1:25052070011:android:5d89f85753b5c881d662de",
        messagingSenderId: "25052070011",
        projectId: "paglachat",
        storageBucket: "paglachat.firebasestorage.app",
        databaseURL: "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
      ),
    );
    print("ফায়ারবেস সফলভাবে কানেক্ট হয়েছে!");
  } catch (e) {
    print("ফায়ারবেস কানেক্ট হয়নি: $e");
  }
  runApp(const PaglaChatApp());
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.pinkAccent),
      home: const SplashScreen(), // শুরু হবে লোগো দিয়ে
    );
  }
}

// ১. স্প্ল্যাশ স্ক্রিন (৩ সেকেন্ড)
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
      // ৩ সেকেন্ড পর চেক করবে ইউজার কি আগে থেকে লগইন করা?
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Image.asset('assets/logo.png', width: 180), // আপনার লোগো
      ),
    );
  }
}

// ২. লগইন স্ক্রিন (ফায়ারবেস অথেন্টিকেশন)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      // ফায়ারবেস দিয়ে লগইন
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // লগইন সফল হলে হোম পেজে যাবে
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ভুল ইমেইল বা পাসওয়ার্ড: $e")));
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "আপনার ইমেইল", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "পাসওয়ার্ড", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _signIn,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
              child: const Text("লগইন করে প্রবেশ করুন"),
            ),
          ],
        ),
      ),
    );
  }
}
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // ফাইল ভাগ করার পর লিস্টটা হবে এইরকম:
  final List<Widget> _pages = [
    const HomePage(),    // home_page.dart থেকে আসবে
    const VoiceRoom(),   // voice_room.dart থেকে আসবে
    const InboxPage(),   // inbox_page.dart থেকে আসবে
    const ProfilePage(), // profile_page.dart থেকে আসবে
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

// এই ফাংশনটি ইউজার প্রোফাইল এবং ফিক্সড আইডি তৈরি করবে
Future<void> initializeUserInFirestore(User user, String name) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  // চেক করছি এই ইউজারের ডাটা আগে থেকে আছে কিনা
  DocumentSnapshot userDoc = await db.collection('users').doc(user.uid).get();

  if (!userDoc.exists) {
    // যদি না থাকে, তবেই নতুন ৬ ডিজিটের ফিক্সড আইডি তৈরি হবে
    String uID = (100000 + Random().nextInt(900000)).toString();
    String rID = (100000 + Random().nextInt(900000)).toString();

    await db.collection('users').doc(user.uid).set({
      'uID': uID,          // এটি তার চিরস্থায়ী ইউজার আইডি
      'roomID': rID,       // এটি তার চিরস্থায়ী রুম আইডি
      'name': name,
      'profilePic': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("নতুন ইউজার প্রোফাইল ও আইডি তৈরি হয়েছে!");
  } else {
    print("ইউজার আইডি আগে থেকেই আছে।");
  }
}
