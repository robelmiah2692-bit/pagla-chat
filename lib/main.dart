import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pagla_chat/app_update_manager.dart';
import 'package:pagla_chat/device_service.dart';
import 'package:pagla_chat/reels_page.dart';

import 'auth_service.dart';
import 'package:pagla_chat/services/notification_service.dart';

// ফায়ারবেস প্যাকেজ
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// আপনার তৈরি করা অন্যান্য পেজ
import 'home_page.dart';
import 'inbox_page.dart';
import 'profile_page.dart';
import 'room_list_page.dart';

// 🔥 [The Final Roadmap] মেইন ডাটা সুইচবোর্ড
class AppData {
  static String myID = ""; // ৬-ডিজিটের ইউনিক আইডি
  static String myName = "";
  static String myImage = "";
}

// ফায়ারবেস কনফিগারেশন
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyA9KMdtIBNVYSASc5C2w5JGVTL-NISXFog",
  authDomain: "paglachat.firebaseapp.com",
  databaseURL:
      "https://paglachat-default-rtdb.asia-southeast1.firebasedatabase.app",
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

  // 🔥 অ্যাপ চালুর সাথেই অ্যাডমব ইনিশিয়ালাইজ করা হলো
  await MobileAds.instance.initialize();

  try {
    // ১. ফায়ারবেস ইনিশিয়ালাইজেশন
    await Firebase.initializeApp(options: firebaseOptions);

    final updateManager = AppUpdateManager();
    updateManager.checkForUpdates();
    // ২. ডিভাইস ব্লক চেক (নতুন ফিচার)
    // এটি অ্যাপ ওপেন হওয়ার সাথে সাথেই ডাটাবেস চেক করবে
    bool isBlocked = await DeviceService.isDeviceBlocked();

    if (isBlocked) {
      // যদি ব্লকড থাকে, তাহলে অ্যাপ আর লোড হবে না, এই স্ক্রিনটিই দেখাবে
      runApp(const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              "Your device has been blocked!\nPlease contact the admin for assistance.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ));
      return; // কোড এখানেই থেমে যাবে
    }

    // ৩. ব্লক না থাকলে স্বাভাবিক নোটিফিকেশন লজিক
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      try {
        await NotificationService().initNotification();
      } catch (e) {}
    }
  } catch (e) {
    debugPrint("Error initializing app: $e");
  }

  // সব ঠিক থাকলে অ্যাপ রান করবে
  runApp(const PaglaChatApp());
}

class MyRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint(
        "🟢 [NAVIGATION] পেজে প্রবেশ করা হয়েছে: ${route.settings.name ?? route.toString()}");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint(
        "🔴 [NAVIGATION] পেজ বন্ধ বা POP হয়েছে: ${route.settings.name ?? route.toString()}");
  }
}

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [MyRouteObserver()],
      title: 'Pagla Chat',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF302B63),
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2F).withOpacity(0.8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2F),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          prefixIconColor: Colors.pinkAccent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0C29),
          selectedItemColor: Colors.pinkAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class CosmicBackground extends StatelessWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0C29),
            Color(0xFF302B63),
            Color(0xFF24243E),
          ],
        ),
      ),
      child: child,
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
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          // AppData.myID = userDoc.docs.first.id;
          if (mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MainNavigation()));
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const CreateProfilePage()));
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.28;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // আপনার কাঙ্ক্ষিত রেডিয়েন্ট গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Color(0xFF063838), // Center dark emerald/teal glow tone
              Color(0xFF031633), // Mid deep blue
              Color(0xFF050514), // Outer dark cosmos boundary
            ],
            stops: [0.1, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ১. টপ-রাইট ম্যাজেন্টা/পার্পল গ্লো ইফেক্ট
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent.withOpacity(0.35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.5),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // ২. बॉटम-লেফট সায়ান/ব্লু গ্লো ইফেক্ট
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // ৩. ব্যাকগ্রাউন্ডের ছোট ছোট আলোর কণা বা স্টার ডাস্ট
            ...List.generate(
              25,
              (index) => Positioned(
                top: (index * 37.0) % 800,
                left: (index * 29.0) % 400,
                child: Container(
                  width: index % 3 == 0 ? 4 : 2,
                  height: index % 3 == 0 ? 4 : 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index % 2 == 0 ? Colors.cyanAccent : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.8),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ৪. আসল লোগো, স্টাইলিশ গ্রেডিয়েন্ট টেক্সট এবং লোডার ঠিক মাঝখানে
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // লোগো ইমেজ
                  Image.asset(
                    'assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),

                  // লোগোর সাথে ম্যাচিং করা স্টাইলিশ গ্রেডিয়েন্ট টেক্সট
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD700), // ব্রাইট গোল্ডেন (Pagla অংশের জন্য)
                        Color(0xFFFFA500), // ডিপ গোল্ড
                        Color(0xFFFF007F), // নিয়ন পিংক/ম্যাজেন্টা
                        Color(0xFF00FFFF), // সায়ান/ব্লু (Chat অংশের জন্য)
                      ],
                      stops: [0.0, 0.4, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: const Text(
                      "PAGLA CHAT",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors
                            .white, // ShaderMask কাজ করার জন্য হোয়াইট থাকতে হবে
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // সাবটাইটেল
                  const Text(
                    "LIVE VOICE CHAT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 25),
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ক্রিয়েট প্রোফাইল পেজ (ফিক্সড ডাটা লজিক) ---
// --- প্রফাইল ক্রিয়েট পেইজ (মাল্টি-কালার গ্লোয়িং ডিজাইন ও আগের সব লজিকসহ) ---
class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = "Male";
  bool _isSaving = false;
  int? _selectedAgeValue;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // বয়স সিলেক্ট করার জন্য মাল্টি-কালার গ্লোয়িং ডায়ালগ পিকার
  void _showAgePicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          height: 320,
          width: double.maxFinite,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a40), Color(0xFF2b0d3f), Color(0xFF0f2027)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "SELECT YOUR AGE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 1.2,
                ),
              ),
              const Divider(color: Colors.pinkAccent, thickness: 1.5),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: 40, // ১৫ থেকে ৫৪ বছর পর্যন্ত
                  itemBuilder: (context, index) {
                    int calculatedAge = index + 15;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.2),
                            Colors.purple.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: ListTile(
                        title: Text(
                          "$calculatedAge Years",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedAgeValue = calculatedAge;
                            _ageController.text = calculatedAge.toString();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFinalProfile() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? currentDeviceId = await DeviceService.getDeviceId();
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    final random = Random();

    String finaluID = "";
    bool uniqueFound = false;

    while (!uniqueFound) {
      int num = 100000000 + random.nextInt(900000000);
      finaluID = num.toString();
      var check = await firestore.collection('users').doc(finaluID).get();
      if (!check.exists) uniqueFound = true;
    }

    try {
      await firestore.collection('users').doc(finaluID).set({
        'uID': finaluID,
        'deviceId': currentDeviceId,
        'name': _nameController.text.trim(),
        'age':
            int.tryParse(_ageController.text.trim()) ?? _selectedAgeValue ?? 15,
        'gender': _selectedGender,
        'email': user?.email,
        'uid': user?.uid,
        'authUID': user?.uid,
        'diamonds': 200,
        'vip_xp': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppData.myID = finaluID;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // টাইটেল উইজেট গ্লোয়িং ইফেক্টসহ
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Colors.cyanAccent,
                        Colors.pinkAccent,
                        Colors.purpleAccent
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      "COMPLETE YOUR PROFILE",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // ১. নাম ইনপুট ফিল্ড (মাল্টি-কালার বর্ডার ও গ্লাস ইফেক্ট)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.15),
                          Colors.purpleAccent.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      maxLength: 13, // সর্বোচ্চ ১৩ ডিজিট/ক্যারেক্টার লিমিট
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Full Name (Max 13 chars)",
                        labelStyle: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.8)),
                        prefixIcon:
                            const Icon(Icons.person, color: Colors.cyanAccent),
                        counterStyle: const TextStyle(color: Colors.white60),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                              color: Colors.cyanAccent.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Colors.pinkAccent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ২. বয়স ইনপুট ফিল্ড (মাল্টি-কালার বর্ডার ও গ্লাস ইফেক্ট)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purpleAccent.withOpacity(0.15),
                          Colors.pinkAccent.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ageController,
                      readOnly: true,
                      onTap: _showAgePicker,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Age (15+)",
                        labelStyle: TextStyle(
                            color: Colors.pinkAccent.withOpacity(0.8)),
                        prefixIcon:
                            const Icon(Icons.cake, color: Colors.pinkAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                              color: Colors.pinkAccent.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                              color: Colors.cyanAccent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // জেন্ডার সিলেকশন রেডিও বাটন (মাল্টি-কালার থিম)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "Male",
                        groupValue: _selectedGender,
                        activeColor: Colors.cyanAccent,
                        onChanged: (v) =>
                            setState(() => _selectedGender = v.toString()),
                      ),
                      const Text("Male",
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 30),
                      Radio<String>(
                        value: "Female",
                        groupValue: _selectedGender,
                        activeColor: Colors.pinkAccent,
                        onChanged: (v) =>
                            setState(() => _selectedGender = v.toString()),
                      ),
                      const Text("Female",
                          style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 35),

                  // ৩. START CHATTING বাটন (আকর্ষণীয় মাল্টি-কালার গ্রেডিয়েন্ট ও গ্লোয়িং শ্যাডো)
                  _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.cyanAccent)
                      : Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.cyan,
                                Colors.blueAccent,
                                Colors.purpleAccent,
                                Colors.pinkAccent
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _createFinalProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "START CHATTING",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- মেইন নেভিগেশন (এখানে টাইমার, হার্টবিট ও সঠিক পেজ সুইচিং বসানো হয়েছে) ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _heartbeatTimer; // 🔥 অনলাইন স্ট্যাটাস এবং হার্টবিট টাইমার

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // অ্যাপ লাইফসাইকেল ট্র্যাক করার জন্য
    _updateFCMToken();
    _updateDeviceIdIfMissing();

    // 🔥 অ্যাপ চালুর সাথে সাথেই অনলাইন স্ট্যাটাস আপডেট করা
    _updateUserPresence(true);

    // 🔥 প্রতি ৩০ সেকেন্ড পর পর ফায়ারস্টোরে `lastSeen` ও `isOnline` আপডেট করবে (হার্টবিট)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateUserPresence(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true); // অ্যাপে ফিরে আসলে অনলাইন
    } else {
      _updateUserPresence(
          false); // ব্যাকগ্রাউন্ডে চলে গেলে বা মিনিমাইজ করলে অফলাইন
    }
  }

  // 🔥 ফায়ারস্টোরে স্ট্যাটাস আপডেট করার ফাংশন
  Future<void> _updateUserPresence(bool isOnline) async {
    if (AppData.myID.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AppData.myID)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating presence: $e");
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel(); // টাইমার বন্ধ করা
    WidgetsBinding.instance.removeObserver(this);
    _updateUserPresence(false); // পেজ ডিসপোজ হলে অফলাইন করে দেওয়া
    super.dispose();
  }

  void _updateFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && AppData.myID.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(AppData.myID)
            .update({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  void _updateDeviceIdIfMissing() async {
    try {
      String deviceId = await DeviceService.getDeviceId();
      if (AppData.myID.isNotEmpty) {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(AppData.myID);
        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists) {
          String? existingId = userDoc.get('deviceId');

          if (existingId == null ||
              existingId == "AP3A.240905.015.A2" ||
              existingId.isEmpty) {
            await userRef.update({'deviceId': deviceId});
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating device ID: $e");
    }
  }

  // ইউজার যেই পেজে থাকবে, শুধুমাত্র সেই পেজটিই রেন্ডার হবে (অন্য পেজ সম্পূর্ণ ডিসপোজ হয়ে যাবে)
  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return ReelsPage(isActive: _currentIndex == 1);
      case 2:
        return const RoomListPage();
      case 3:
        return const InboxPage();
      case 4:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = AppData.myID;

    return Scaffold(
      extendBody:
          false, // 🔥 কন্টেন্ট যেন নেভিগেশন বারের নিচে না যায়, সেফ রাখার জন্য false করা হলো
      backgroundColor: Colors.black,
      // ডাইনামিক সুইচিং ব্যবহার করা হলো যাতে অন্য ট্যাবে গেলে রিলস বা ভিডিও বন্ধ থাকে
      body: SafeArea(
        bottom: false, // যেহেতু নিচে কাস্টম নেভিগেশন বার আছে
        child: _getSelectedPage(_currentIndex),
      ),
      bottomNavigationBar: Container(
        // 🔥 পরিবর্তন ১: নিচে কালো ব্যাকগ্রাউন্ডের বদলে একটি সুন্দর রঙিন গ্রেডিয়েন্ট ডিজাইন বসানো হলো
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF14082C),
              Color(0xFF2A0845),
              Color(0xFF14082C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            // 🔥 পরিবর্তন ২: উচ্চতা ও নিচের ফাঁকা জায়গা বা মার্জিন কমিয়ে ছোট করা হলো
            height: 65,
            margin:
                const EdgeInsets.only(left: 15, right: 15, bottom: 2, top: 2),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ব্যাকগ্রাউন্ড কার্ভড কালারফুল নেভিগেশন বার
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFF14082C), // ডিপ রয়্যাল পার্পল ও ব্ল্যাক থিম
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, "Home", false,
                            currentUserId),
                        _buildNavItem(1, Icons.video_collection_rounded,
                            "Reels", false, currentUserId),
                        const SizedBox(
                            width: 50), // মাঝখানের রুম বাটনের জন্য গ্যাপ
                        _buildNavItem(3, Icons.mail_rounded, "Message", true,
                            currentUserId),
                        _buildNavItem(4, Icons.person_rounded, "Profile", false,
                            currentUserId),
                      ],
                    ),
                  ),
                ),
                // মাঝখানের গোল রুম বাটন (হালকা উপরে ভাসমান এবং আকর্ষণীয় গ্রেডিয়েন্ট সহ)
                Positioned(
                  top: -10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Rooms page index
                      });
                    },
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF2E93),
                            Color(0xFF9C27B0),
                            Color(0xFF00E5FF)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2E93).withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: _currentIndex == 2
                              ? Colors.amberAccent
                              : Colors.white,
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // কালারফুল বাটন এবং ডিজিটাল কালারিং চ্যাট আইকন উইজেট
  Widget _buildNavItem(int index, IconData icon, String label, bool isInbox,
      String currentUserId) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isInbox
                ? (currentUserId.isEmpty
                    ? Icon(icon,
                        color: isSelected
                            ? const Color(0xFFFF4081)
                            : Colors.white60,
                        size: 22)
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('messages')
                            .where('receiverId', isEqualTo: currentUserId)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Icon(icon,
                                color: isSelected
                                    ? const Color(0xFFFF4081)
                                    : Colors.white60,
                                size: 22);
                          }
                          int unreadCount =
                              snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return Badge(
                            label: unreadCount > 0
                                ? Text('$unreadCount',
                                    style: const TextStyle(
                                        fontSize: 9, color: Colors.white))
                                : null,
                            isLabelVisible: unreadCount > 0,
                            backgroundColor: Colors.redAccent,
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF00E5FF),
                                  Color(0xFF7C4DFF),
                                  Color(0xFFFF4081)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ))
                : ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isSelected
                          ? [
                              const Color(0xFFFF4081),
                              const Color(0xFFE040FB),
                              const Color(0xFF00E5FF)
                            ]
                          : [Colors.white70, Colors.white38],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF4081) : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- লগইন স্ক্রিন (গুগল সাইন-ইন ও ডিলিটেড ইউজার চেকিং লজিকসহ) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _rocketAnimController;
  late AnimationController _smokeAnimController;
  late AnimationController
      _shimmerAnimController; // শিমার শাইনিং অ্যানিমেশন কন্ট্রোলার

  @override
  void initState() {
    super.initState();
    // রকেট ও ধোঁয়ার রিয়েল লাইফ অ্যানিমেশন কন্ট্রোলার (চলতে থাকবে)
    _rocketAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _smokeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // শিমার শাইনিং ইফেক্টের জন্য কন্ট্রোলার (সময় একটু বাড়িয়ে স্মুথ করা হয়েছে)
    _shimmerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _rocketAnimController.dispose();
    _smokeAnimController.dispose();
    _shimmerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.22; // লোগোর সাইজ রেসপনসিভ রাখার জন্য

    return Scaffold(
      body: CosmicBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ১. রকেট, ফায়ার ও ধোঁয়ার অ্যানিমেটেড উইজেট
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _rocketAnimController,
                      _smokeAnimController,
                      _shimmerAnimController
                    ]),
                    builder: (context, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // রকেট উইজেট
                          Transform.translate(
                            offset: Offset(0,
                                sin(_rocketAnimController.value * 2 * pi) * 6),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orangeAccent.withOpacity(
                                            0.6 +
                                                (_rocketAnimController.value *
                                                    0.4)),
                                        blurRadius: 25,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.pinkAccent.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: CustomPaint(
                                    size: const Size(80, 90),
                                    painter: RocketPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // রকেটের ইঞ্জিন থেকে বের হওয়া রিয়েল ফায়ার ও ধোঁয়া
                          SizedBox(
                            height: 70,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Positioned(
                                  top: 0,
                                  child: Container(
                                    width: 16,
                                    height: 25 +
                                        (sin(_rocketAnimController.value *
                                                2 *
                                                pi) *
                                            5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.yellow,
                                          Colors.orange,
                                          Colors.red
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 15,
                                  child: SizedBox(
                                    width: 80,
                                    height: 50,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: List.generate(4, (index) {
                                        double progress =
                                            (_smokeAnimController.value +
                                                    (index * 0.25)) %
                                                1.0;
                                        double sizeFactor =
                                            10.0 + (progress * 14);

                                        return Positioned(
                                          top: progress * 40,
                                          child: Transform.translate(
                                            offset: Offset(
                                                sin(progress * 2 * pi + index) *
                                                    10,
                                                0),
                                            child: Opacity(
                                              opacity: (1.0 - progress)
                                                  .clamp(0.0, 1.0),
                                              child: Container(
                                                width: sizeFactor,
                                                height: sizeFactor,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white
                                                          .withOpacity(0.9),
                                                      Colors.cyanAccent
                                                          .withOpacity(0.4),
                                                      Colors.transparent,
                                                    ],
                                                    stops: const [
                                                      0.2,
                                                      0.7,
                                                      1.0
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      blurRadius: 6,
                                                      spreadRadius: 2,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ২. পিএনজি লোগো যার ওপর হালকা ও পাতলা শাইনিং লাইট ইফেক্ট দেওয়া হয়েছে
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // মূল লোগো
                                Image.asset(
                                  'assets/logo.png',
                                  width: logoSize,
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                ),
                                // লোগোর ওপর স্লাইড হওয়া হালকা শাইনিং লাইট বিম (অত্যন্ত পাতলা ও স্বচ্ছ)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(logoSize / 2),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        double pos = (_shimmerAnimController
                                                    .value *
                                                (constraints.maxWidth * 2.5)) -
                                            constraints.maxWidth;
                                        return Transform.translate(
                                          offset: Offset(pos, 0),
                                          child: Transform.rotate(
                                            angle:
                                                0.35, // হালকা কোনাকোনি বা বাঁকা করার জন্য
                                            child: Container(
                                              width:
                                                  25, // লাইট বিম আরও চিকন করা হয়েছে
                                              height:
                                                  constraints.maxHeight * 1.5,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withOpacity(0.0),
                                                    Colors.white.withOpacity(
                                                        0.25), // গাঢ় ভাব কমিয়ে একদম হালকা করা হয়েছে
                                                    Colors.white
                                                        .withOpacity(0.0),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text("WELCOME TO PAGLA CHAT",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 40),

                  // গুগল সাইন-ইন বাটন (মূল ফাংশনালিটি সহ)
                  _buildSocialButton(
                    text: "CONTINUE WITH GOOGLE",
                    icon: Icons.g_mobiledata,
                    color: Colors.white,
                    onPressed: () async {
                      // গুগল লগইন প্রসেস
                      var user = await AuthService().signInWithGoogle();

                      if (user != null && mounted) {
                        // ১. প্রথমে চেক করুন ইউজার ডিলিট করা কি না
                        bool deleted =
                            await AuthService().isUserDeleted(user.email ?? "");

                        if (deleted) {
                          // যদি ডিলিট করা থাকে, লগআউট করে দিন এবং মেসেজ দেখান
                          await AuthService().signOut();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Your account has been deleted. Please contact the support team to recover it."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          // ২. যদি ডিলিট করা না থাকে, তাহলে চেক করুন সে রেজিস্টার্ড কি না
                          bool registered = await AuthService()
                              .isUserRegistered(user.email ?? "");

                          if (registered) {
                            // পুরাতন ইউজার হলে সরাসরি মেইন অ্যাপে
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SplashScreen()),
                            );
                          } else {
                            // নতুন ইউজার হলে প্রোফাইল ক্রিয়েট পেইজে
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateProfilePage()),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // বাটন তৈরির জন্য কমন উইজেট
  Widget _buildSocialButton(
      {required String text,
      required IconData icon,
      required Color color,
      Color textColor = Colors.black,
      required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 10),
          Text(text,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- আপনার ছবির কালার অনুযায়ী নিখুঁত রকেট পেইন্টার ---
class RocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;

    final Rect bodyRect = Rect.fromLTWH(size.width * 0.25, size.height * 0.15,
        size.width * 0.5, size.height * 0.7);
    paint.shader = const LinearGradient(
      colors: [Color(0xFFFFD54F), Color(0xFFFF5722), Color(0xFFE91E63)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bodyRect);

    Path bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(25)));
    canvas.drawPath(bodyPath, paint);

    Path nosePath = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.25, size.height * 0.25)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..close();
    paint.shader = const LinearGradient(
      colors: [Colors.yellowAccent, Color(0xFFFF9800)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(
        size.width * 0.25, 0, size.width * 0.5, size.height * 0.25));
    canvas.drawPath(nosePath, paint);

    paint.shader = const LinearGradient(
      colors: [Color(0xFFFF5722), Color(0xFFC2185B)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(
        Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.4));

    Path leftWing = Path()
      ..moveTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.25, size.height * 0.8)
      ..close();
    canvas.drawPath(leftWing, paint);

    Path rightWing = Path()
      ..moveTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width * 0.75, size.height * 0.8)
      ..close();
    canvas.drawPath(rightWing, paint);

    Paint windowBg = Paint()..color = const Color(0xFF00E5FF);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38),
        size.width * 0.13, windowBg);

    Paint windowBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38),
        size.width * 0.13, windowBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
