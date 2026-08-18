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
          AppData.myID = userDoc.docs.first.id;
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
    return const Scaffold(
      body: CosmicBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, size: 100, color: Colors.pinkAccent),
              SizedBox(height: 20),
              Text("PAGLA CHAT",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white)),
              SizedBox(height: 10),
              CircularProgressIndicator(color: Colors.pinkAccent),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ক্রিয়েট প্রোফাইল পেজ (ফিক্সড ডাটা লজিক) ---
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

  Future<void> _createFinalProfile() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")));
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
      // ৯ ডিজিটের ইউনিক আইডি জেনারেশন (100000000 থেকে 999999999 এর মধ্যে)
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
        'age': _ageController.text.trim(),
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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainNavigation()));
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
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("COMPLETE YOUR PROFILE",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: "Full Name", prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                      labelText: "Age", prefixIcon: Icon(Icons.cake)),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(
                      value: "Male",
                      groupValue: _selectedGender,
                      activeColor: Colors.pinkAccent,
                      onChanged: (v) =>
                          setState(() => _selectedGender = v.toString())),
                  const Text("Male"),
                  Radio(
                      value: "Female",
                      groupValue: _selectedGender,
                      activeColor: Colors.pinkAccent,
                      onChanged: (v) =>
                          setState(() => _selectedGender = v.toString())),
                  const Text("Female"),
                ],
              ),
              const SizedBox(height: 30),
              _isSaving
                  ? const CircularProgressIndicator(color: Colors.pinkAccent)
                  : ElevatedButton(
                      onPressed: _createFinalProfile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("START CHATTING",
                          style: TextStyle(color: Colors.white)),
                    ),
            ],
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
    WidgetsBinding.instance.addObserver(this); // অ্যাপ লাইফসাইকেল ট্র্যাক করার জন্য
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
      _updateUserPresence(false); // ব্যাকগ্রাউন্ডে চলে গেলে বা মিনিমাইজ করলে অফলাইন
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
      extendBody: false, // 🔥 কন্টেন্ট যেন নেভিগেশন বারের নিচে না যায়, সেফ রাখার জন্য false করা হলো
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
            margin: const EdgeInsets.only(left: 15, right: 15, bottom: 2, top: 2),
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
                      color: const Color(0xFF14082C), // ডিপ রয়্যাল পার্পল ও ব্ল্যাক থিম
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
                        _buildNavItem(0, Icons.home_rounded, "Home", false, currentUserId),
                        _buildNavItem(1, Icons.video_collection_rounded, "Reels", false, currentUserId),
                        const SizedBox(width: 50), // মাঝখানের রুম বাটনের জন্য গ্যাপ
                        _buildNavItem(3, Icons.mail_rounded, "Message", true, currentUserId),
                        _buildNavItem(4, Icons.person_rounded, "Profile", false, currentUserId),
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

class _LoginScreenState extends State<LoginScreen> {
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
                  const Icon(Icons.rocket_launch,
                      size: 100, color: Colors.pinkAccent),
                  const SizedBox(height: 30),
                  const Text("WELCOME TO PAGLA CHAT",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 50),

                  // গুগল সাইন-ইন বাটন
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
                                    builder: (context) =>
                                        const SplashScreen()));
                          } else {
                            // নতুন ইউজার হলে প্রোফাইল ক্রিয়েট পেইজে
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateProfilePage()));
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
