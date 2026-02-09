import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ফায়ারবেস চালু করার কমান্ড
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase Error: $e");
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PaglaChatLoginPage(),
  ));
}

class PaglaChatLoginPage extends StatelessWidget {
  // জিমেইল লগইন ফাংশন
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        print("লগইন সফল হয়েছে!");
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A0033), // বেগুনি থিম
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // লোগো (আপনার assets/logo.jpg এখানে থাকবে)
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Icon(Icons.mic, size: 70, color: Colors.purple), 
            ),
            SizedBox(height: 30),
            Text("পাগলা চ্যাট", style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold)),
            SizedBox(height: 50),

            // জিমেইল লগইন বাটন
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => signInWithGoogle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Continue with Gmail", style: TextStyle(color: Colors.black, fontSize: 18)),
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
