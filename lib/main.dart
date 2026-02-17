import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // ফায়ারবেস ইমপোর্ট
import 'package:firebase_auth/firebase_auth.dart'; // লগইন ইমপোর্ট
// আপনার তৈরি করা অন্যান্য পেজগুলো ইমপোর্ট করুন
// import 'home_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ফায়ারবেস চালু করা
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
