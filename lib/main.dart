import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pagla_chat/app_update_manager.dart';
import 'package:pagla_chat/device_service.dart';
import 'package:pagla_chat/reels_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isCheckingUpdate = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ফায়ারস্টোর থেকে ভার্সন চেক এবং সিকোয়েন্স মেইনটেইন করার ফাংশন
  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    bool updateNeeded = await _checkVersionAndForceUpdate();

    if (!updateNeeded && mounted) {
      _proceedWithNavigation();
    }
  }

  // ১. ভার্সন চেক করার লজিক
  Future<bool> _checkVersionAndForceUpdate() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      DocumentSnapshot versionDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('version_control')
          .get();

      if (versionDoc.exists) {
        var data = versionDoc.data() as Map<String, dynamic>;
        String latestVersion = data['latest_version'] ?? "1.0.0";
        bool isForceUpdate = data['is_force_update'] ?? false;

        if (_isVersionLessThan(currentVersion, latestVersion)) {
          if (mounted) {
            setState(() {
              _isCheckingUpdate = false;
            });
            _showUpdateDialog(isForceUpdate);
            return true;
          }
        }
      }
    } catch (e) {
      // Error handling without print
    }
    return false;
  }

  // ২. ভার্সন নাম্বার তুলনা করার ফাংশন
  bool _isVersionLessThan(String current, String latest) {
    List<String> currentParts = current.split('.');
    List<String> latestParts = latest.split('.');

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
      int l = i < latestParts.length ? int.tryParse(latestParts[i]) ?? 0 : 0;

      if (c < l) return true;
      if (c > l) return false;
    }
    return false;
  }

  // ৩. আপডেট পপআপ ডায়ালগ (ইংরেজি টেক্সটসহ)
  void _showUpdateDialog(bool isForceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !isForceUpdate,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            title: const Text(
              "🚀 New Update Available!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "A new and improved version of our app is available on the Play Store. Please update the app for the best experience.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              if (!isForceUpdate)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _proceedWithNavigation();
                  },
                  child: const Text("Later", style: TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(
                    "https://play.google.com/store/apps/details?id=com.pagla.chat&pcampaignid=web_share",
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ৪. ইউজার লগইন স্ট্যাটাস চেক করে নির্দিষ্ট পেজে নিয়ে যাওয়ার লজিক
  void _proceedWithNavigation() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userDoc.docs.isNotEmpty) {
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
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.28;

    // =========================================================================
    // 🎯 লোগো ও "PAGLA CHAT" লেখা কতটা নিচে নামাবেন তা এখান থেকে কন্ট্রোল করুন:
    // 👉 সংখ্যাটি বাড়ালে (যেমন 90, 110, 130) আরও নিচে নামবে।
    // 👉 কমালে (যেমন 40, 20) ওপরে উঠবে।
    // =========================================================================
    double topOffset = 420;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splshwall.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: topOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                          Color(0xFFFF007F),
                          Color(0xFF00FFFF),
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
                          color: Colors.white,
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

// --- মেইন নেভিগেশন (পাকাপোক্ত অনলাইন/অফলাইন স্ট্যাটাস হ্যান্ডেলার সহ) ---
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
    WidgetsBinding.instance.addObserver(this);
    _updateFCMToken();
    _updateDeviceIdIfMissing();

    // 🔥 অ্যাপ চালুর সাথে সাথেই অনলাইন স্ট্যাটাস true করা
    _updateUserPresence(true);

    // 🔥 প্রতি ৩০ সেকেন্ড পর পর ফায়ারস্টোরে হার্টবিট পাঠানো
    _startHeartbeat();
  }

  // হার্টবিট শুরু করার ফাংশন
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // শুধুমাত্র অ্যাপ ফোরগ্রাউন্ডে থাকলেই হার্টবিট ট্রু করবে
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _updateUserPresence(true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true); // অ্যাপে ফিরে আসলে অনলাইন
      _startHeartbeat(); // হার্টবিট পুনরায় চালু
    } else {
      _heartbeatTimer?.cancel(); // ব্যাকগ্রাউন্ডে গেলে টাইমার বন্ধ
      _updateUserPresence(false); // সাথে সাথে অফলাইন করে দেওয়া
    }
  }

  // 🔥 ফায়ারস্টোরে স্ট্যাটাস আপডেট করার ফাংশন
  Future<void> _updateUserPresence(bool isOnline) async {
    if (AppData.myID.isEmpty) return;
    try {
      Map<String, dynamic> updateData = {
        'lastSeen': FieldValue.serverTimestamp(),
      };

      // যদি অফলাইন হয়, তবে সরাসরি isOnline false করে দেবো
      // আর যদি অনলাইন হয়, তবে true করব
      updateData['isOnline'] = isOnline;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(AppData.myID)
          .update(updateData);
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
      extendBody: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: _getSelectedPage(_currentIndex),
      ),
      bottomNavigationBar: Container(
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
            height: 65,
            margin:
                const EdgeInsets.only(left: 15, right: 15, bottom: 2, top: 2),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14082C),
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
                        _buildNavItem(0, 'assets/images/nav_home.webp',
                            "Home", false, currentUserId),
                        _buildNavItem(1, 'assets/images/nav_reels.webp',
                            "Reels", false, currentUserId),
                        const SizedBox(width: 50),
                        _buildNavItem(3, 'assets/images/nav_message.webp',
                            "Message", true, currentUserId),
                        _buildNavItem(4, 'assets/images/nav_profile.webp',
                            "Profile", false, currentUserId),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                    child: SizedBox(
                      width: 55,
                      height: 55,
                      child: Image.asset(
                        'assets/images/nav_mic.webp',
                        width: 55,
                        height: 55,
                        fit: BoxFit.contain,
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

  Widget _buildNavItem(int index, String assetPath, String label, bool isInbox,
      String currentUserId) {
    bool isSelected = _currentIndex == index;

    Widget navImage = AnimatedScale(
      scale: isSelected ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.78,
        duration: const Duration(milliseconds: 220),
        child: Image.asset(
          assetPath,
          width: 34,
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );

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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isInbox
                ? (currentUserId.isEmpty
                    ? navImage
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('messages')
                            .where('receiverId', isEqualTo: currentUserId)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return navImage;
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
                            child: navImage,
                          );
                        },
                      ))
                : navImage,
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF4081) : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 8.0,
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double logoSize = screenWidth * 0.28; // লোগোর সাইজ রেসপনসিভ রাখার জন্য

    // =========================================================================
    // 🎯 লোগো, ওয়েলকাম লেখা ও গুগল বাটন কতটা নিচে নামাবেন তা এখান থেকে কন্ট্রোল করুন:
    // 👉 সংখ্যাটি বাড়ালে (যেমন 110, 140) আরও নিচে নামবে।
    // 👉 কমালে (যেমন 50, 30) ওপরে উঠবে।
    // =========================================================================
    double topOffset = 420;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // অ্যাসেট থেকে ব্যাকগ্রাউন্ড ওয়ালপেপার সেট করা হলো
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/images/splshwall.webp'), // আপনার ব্যাকগ্রাউন্ড ইমেজের পাথ এখানে দিন
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(25.0, topOffset, 25.0, 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // লোগো উইজেট (রকেট ও শিমার শাইনিং বাদ দেওয়া হয়েছে)
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    'assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700), // ব্রাইট গোল্ডেন
                      Color(0xFFFFA500), // ডিপ গোল্ড
                      Color(0xFFFF007F), // নিয়ন পিংক/ম্যাজেন্টা
                      Color(0xFF00FFFF), // সায়ান/ব্লু
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: const Text(
                    "—͟͟͞͞★ 𝓦𝓮𝓵𝓬𝓸𝓶𝓮 𝓣𝓸 𝓟𝓪𝓰𝓵𝓪𝓒𝓱𝓪𝓽 ☯",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .white, // ShaderMask কাজ করার জন্য এটি হোয়াইট থাকতে হবে
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
                const SizedBox(height: 15),

                // গুগল সাইন-ইন বাটন (মূল ফাংশনালিটি সহ)
                _buildSocialButton(
                  text: "CONTINUE WITH GOOGLE",
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
    );
  }

  // অ্যাপ কালার থিম অনুযায়ী গুগল সাইন-ইন বাটন উইজেট
  Widget _buildSocialButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A0B3B),
                Color(0xFF2B1055),
                Color(0xFF120829),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.55),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.18),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _GoogleOriginalGPainter(),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// গুগলের চার রঙের অরিজিনাল 'G' লোগো আঁকার পেইন্টার
class _GoogleOriginalGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.21;
    final Rect arcRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // লাল অংশ (ওপর-বাম থেকে ওপরে)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.35, 1.30, false, paint);

    // হলুদ অংশ (বাম দিক)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.15, 1.78, false, paint);

    // সবুজ অংশ (নিচ থেকে ডান-নিচে)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.72, 1.43, false, paint);

    // নীল অংশ (ডান দিকের কার্ভ)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.55, 1.27, false, paint);

    // G-এর মাঝখানের আনুভূমিক দাগ (নীল)
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width - strokeWidth * 0.35, size.height * 0.50),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}