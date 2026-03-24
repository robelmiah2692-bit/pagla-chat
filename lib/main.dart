import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'auth_service.dart';
import 'package:pagla_chat/services/notification_service.dart';

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

// ফায়ারবেস কনফিগারেশন
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyA9KMdtIBNVYSASc5C2w5JGVTL-NISXFog",
  authDomain: "paglachat.firebaseapp.com",
  databaseURL: "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "paglachat",
  storageBucket: "paglachat.firebasestorage.app",
  messagingSenderId: "25052070011",
  appId: "1:25052070011:web:7c447f8d011fbdf3d662de",
  measurementId: "G-946LX0V0Q9",
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: firebaseOptions);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: firebaseOptions);

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      try {
        await NotificationService().initNotification(); 
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }
    }

    debugPrint("✅ পাগলা চ্যাট কানেক্ট হয়েছে!");
  } catch (e) {
    debugPrint("❌ কানেকশন এরর: $e");
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
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
      if (!mounted) return;
      
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
  void initState() {
    super.initState();
    _updateFCMToken();
  }

  void _updateFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    User? user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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

// --- লগইন স্ক্রিন (আপডেটেড) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true; // পাসওয়ার্ড লুকানোর জন্য
  String _selectedGender = "পুরুষ"; // ডিফল্ট জেন্ডার

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.pinkAccent),
                const SizedBox(height: 20),
                const Text("WELCOME BACK", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                // ইমেইল ফিল্ড
                TextField(
                  controller: _emailController, 
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email, color: Colors.pinkAccent),
                  ),
                ),
                const SizedBox(height: 15),
                
                // পাসওয়ার্ড ফিল্ড (চোখের আইকন সহ)
                TextField(
                  controller: _passwordController, 
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.pinkAccent),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                ),

                // জেন্ডার সিলেকশন
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("জেন্ডার: "),
                    Radio(
                      value: "পুরুষ",
                      groupValue: _selectedGender,
                      activeColor: Colors.pinkAccent,
                      onChanged: (val) => setState(() => _selectedGender = val.toString()),
                    ),
                    const Text("পুরুষ"),
                    Radio(
                      value: "মহিলা",
                      groupValue: _selectedGender,
                      activeColor: Colors.pinkAccent,
                      onChanged: (val) => setState(() => _selectedGender = val.toString()),
                    ),
                    const Text("মহিলা"),
                  ],
                ),

                // Forget Password বাটন
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      if (_emailController.text.isNotEmpty) {
                        try {
                          await AuthService().sendPasswordReset(_emailController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("আপনার জিমেইল চেক করুন, রিসেট লিঙ্ক পাঠানো হয়েছে।"), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("এরর: ${e.toString()}"), backgroundColor: Colors.red),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("অনুগ্রহ করে আগে ইমেইলটি লিখুন।"), backgroundColor: Colors.orange),
                        );
                      }
                    },
                    child: const Text("Forget Password?", style: TextStyle(color: Colors.pinkAccent)),
                  ),
                ),

                const SizedBox(height: 10),
                
                // লগইন বাটন
                ElevatedButton(
                  onPressed: () async {
                    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("প্রসেসিং হচ্ছে...")),
                      );

                      // জেন্ডার সহ কল করা হচ্ছে
                      var user = await AuthService().loginOrRegister(
                        _emailController.text.trim(), 
                        _passwordController.text.trim(),
                        _selectedGender
                      );

                      if (user != null && mounted) {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => const MainNavigation())
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("লগইন ব্যর্থ! তথ্য চেক করুন।")),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("সবগুলো ঘর পূরণ করুন।")),
                      );
                    }
                  }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("LOGIN / SIGNUP", style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
