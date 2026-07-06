import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pagla_chat/device_service.dart';

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

  try {
    // ১. ফায়ারবেস ইনিশিয়ালাইজেশন
    await Firebase.initializeApp(options: firebaseOptions);

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

class PaglaChatApp extends StatelessWidget {
  const PaglaChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      int num = 100000 + random.nextInt(900000);
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
    const ProfilePage()
  ];

  @override
  void initState() {
    super.initState();
    _updateFCMToken();
    _updateDeviceIdIfMissing();
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

// 🔥 এটি পুরাতন ইউজারের ডাটাবেসে ডিভাইস আইডি বসিয়ে দেবে
  void _updateDeviceIdIfMissing() async {
    try {
      String? deviceId = await DeviceService.getDeviceId();
      if (AppData.myID.isNotEmpty && deviceId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(AppData.myID)
            .update({'deviceId': deviceId});
      }
    } catch (e) {
      debugPrint("Error updating device ID: $e");
    }
  }

  // 🇧🇩 [বাংলা মার্ক]: কোনো প্রিফিক্স ছাড়া, একদম নিরাপদ ও লাল দাগ ফিক্সড ফাংশন
  void clearSpecificChatCount(String chatRoomId) async {
    if (AppData.myID.isEmpty || chatRoomId.isEmpty) return;

    try {
      // 💡 এখানে সুনির্দিষ্ট কোনো টাইপ না লিখে সরাসরি 'final snapshot' ধরা হয়েছে, এতে আর কোনো লাল দাগ আসবে না ভাই
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: AppData.myID)
          .where('isRead', isEqualTo: false)
          .get();

      // 💡 এখানে .docs সরাসরি কাজ করবে
      if (snapshot.docs.isEmpty) return;

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // 💡 প্রতিটা ডকুমেন্টকে dynamic অথবা var রাখায় ডার্ট কনফ্লিক্ট করবে না
      for (dynamic ds in snapshot.docs) {
        batch.update(ds.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // 🇧🇩 [বাংলা মার্ক]: বিল্ড মেথডের শুরুতেই কারেন্ট আইডি ভ্যালিডেশন চেক করা হচ্ছে
    final String currentUserId = AppData.myID;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Rooms"),

          // 🇧🇩 [বাংলা মার্ক - সাব-কালেকশন গ্রুপ ভিত্তিক লাইভ কাউন্ট ব্যাজ]:
          BottomNavigationBarItem(
            icon: currentUserId.isEmpty
                ? const Icon(Icons.mail)
                : StreamBuilder<QuerySnapshot>(
                    // 💡 এখানেও নরমাল QuerySnapshot থাকবে
                    stream: FirebaseFirestore.instance
                        .collectionGroup('messages')
                        .where('receiverId', isEqualTo: currentUserId)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Icon(Icons.mail);
                      }

                      int unreadCount =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Badge(
                        label: unreadCount > 0
                            ? Text('$unreadCount',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white))
                            : null,
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.redAccent,
                        child: const Icon(Icons.mail),
                      );
                    },
                  ),
            label: "Inbox",
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
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
                        bool deleted = await AuthService().isUserDeleted(user.email ?? "");
                        
                        if (deleted) {
                          // যদি ডিলিট করা থাকে, লগআউট করে দিন এবং মেসেজ দেখান
                          await AuthService().signOut();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Your account has been deleted. Please contact the support team to recover it."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          // ২. যদি ডিলিট করা না থাকে, তাহলে চেক করুন সে রেজিস্টার্ড কি না
                          bool registered = await AuthService().isUserRegistered(user.email ?? "");
                          
                          if (registered) {
                            // পুরাতন ইউজার হলে সরাসরি মেইন অ্যাপে
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) => const SplashScreen()));
                          } else {
                            // নতুন ইউজার হলে প্রোফাইল ক্রিয়েট পেইজে
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) => const CreateProfilePage()));
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