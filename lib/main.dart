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

// 🔥 [The Final Roadmap] মেইন ডাটা সুইচবোর্ড
class AppData {
  static String myID = "";      // ৬-ডিজিটের ইউনিক আইডি
  static String myName = "";    
  static String myImage = "";   
}

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

    debugPrint("✅ Pagla Chat connected successfully.");
  } catch (e) {
    debugPrint("❌ Connection Error: $e");
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
        primaryColor: const Color(0xFF302B63),
        scaffoldBackgroundColor: const Color(0xFF0F0C29), 
        
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E2F).withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E2F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
          }
        } else {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CreateProfilePage()));
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
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
              Text("PAGLA CHAT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isSaving = true);
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
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
              const Text("COMPLETE YOUR PROFILE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(controller: _ageController, decoration: const InputDecoration(labelText: "Age", prefixIcon: Icon(Icons.cake)), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(value: "Male", groupValue: _selectedGender, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => _selectedGender = v.toString())),
                  const Text("Male"),
                  Radio(value: "Female", groupValue: _selectedGender, activeColor: Colors.pinkAccent, onChanged: (v) => setState(() => _selectedGender = v.toString())),
                  const Text("Female"),
                ],
              ),
              const SizedBox(height: 30),
              _isSaving 
                ? const CircularProgressIndicator(color: Colors.pinkAccent)
                : ElevatedButton(
                    onPressed: _createFinalProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
                    child: const Text("START CHATTING", style: TextStyle(color: Colors.white)),
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
  final List<Widget> _pages = [const HomePage(), const RoomListPage(), const InboxPage(), const ProfilePage()];

  @override
  void initState() {
    super.initState();
    _updateFCMToken();
  }

  void _updateFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && AppData.myID.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(AppData.myID).update({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
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
      debugPrint("✅ [PaglaChat] চ্যাট রুম: $chatRoomId - এর আনরিড মেসেজ ক্লিয়ার করা হয়েছে।");
      
    } catch (e) {
      debugPrint("❌ Error clearing specific chat unread messages: $e");
    }
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
                : StreamBuilder<QuerySnapshot>( // 💡 এখানেও নরমাল QuerySnapshot থাকবে
                    stream: FirebaseFirestore.instance
                        .collectionGroup('messages')
                        .where('receiverId', isEqualTo: currentUserId)
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint("❌ [PaglaChat Debug] ফায়ারস্টোর কোয়েরি এরর: ${snapshot.error}");
                        return const Icon(Icons.mail);
                      }

                      int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      debugPrint("📩 [PaglaChat Debug] সাব-কালেকশন থেকে মোট আনরিড মেসেজ সংখ্যা: $unreadCount টি");

                      return Badge(
                        label: unreadCount > 0 ? Text('$unreadCount', style: const TextStyle(fontSize: 10, color: Colors.white)) : null,
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.redAccent, 
                        child: const Icon(Icons.mail),
                      );
                    },
                  ),
            label: "Inbox",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
// --- লগইন স্ক্রিন (পাসওয়ার্ড রিসেট অপশনসহ) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true; 

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
                  const Icon(Icons.lock_person, size: 80, color: Colors.pinkAccent),
                  const SizedBox(height: 20),
                  const Text("WELCOME BACK", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController, 
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (_emailController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email first")));
                          return;
                        }
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Reset Email Sent Successfully!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                        }
                      },
                      child: const Text("Forget Password?", style: TextStyle(color: Colors.pinkAccent)),
                    ),
                  ),

                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                        var user = await AuthService().loginOrRegister(
                          _emailController.text.trim(), 
                          _passwordController.text.trim()
                        );
                        if (user != null && mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SplashScreen()));
                        }
                      }
                    }, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
                    child: const Text("CONTINUE", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}