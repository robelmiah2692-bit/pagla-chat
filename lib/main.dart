import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

// ফায়ারবেস প্যাকেজ
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// আপনার তৈরি করা অন্যান্য পেজগুলো (পাথ ঠিক আছে কিনা দেখে নিন)
import 'home_page.dart';
import 'screens/voice_room.dart';
import 'inbox_page.dart';
import 'profile_page.dart';
import 'room_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 🔥 এখানে আপনার নতুন ওয়েব কনফিগ বসানো হয়েছে (SHA-1 ঝামেলা মুক্ত)
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
    print("পাগলা চ্যাট ওয়েব কানেক্ট হয়েছে!");
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

// --- ১. স্প্ল্যাশ স্ক্রিন ---
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
      // অটো লগইন চেক
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // যদি লোগো না থাকে তবে আইকন দেখাবে ক্র্যাশ এড়াতে
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

// --- ২. লগইন স্ক্রিন ---
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
      
      // ইউজার ডাটা চেক/তৈরি করা
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "ইমেইল", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "পাসওয়ার্ড", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
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

// --- ৩. মেইন নেভিগেশন (বটম বার) ---
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

// --- ৪. ফায়ারস্টোর ইউজার আইডি জেনারেশন ---
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
      'profilePic': 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uID', // রিয়েল টাইপ অবতার
      'createdAt': FieldValue.serverTimestamp(),
    });
    print("নতুন ওয়েব প্রোফাইল তৈরি হয়েছে!");
  }
}
