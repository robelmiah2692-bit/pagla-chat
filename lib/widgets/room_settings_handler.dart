/*import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomSettingsHandler {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static void showSettings({
    required BuildContext context,
    required bool isLocked,
    required String roomId,
    required VoidCallback onToggleLock,
    required Function(String) onSetWallpaper,
    required VoidCallback onLeave,
    required VoidCallback onMinimize,
    required VoidCallback onClearChat,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Room Settings",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildItem(isLocked ? Icons.lock : Icons.lock_open,
                      isLocked ? "Unlock" : "Lock", Colors.amber, () {
                    Navigator.pop(context);
                    _handleFeaturePurchase(context, roomId, "room_lock", onToggleLock);
                  }),
                  _buildItem(Icons.wallpaper, "Wallpaper", Colors.cyanAccent, () async {
                    Navigator.pop(context);
                    _handleFeaturePurchase(context, roomId, "wallpaper", () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        onSetWallpaper(image.path);
                      }
                    });
                  }),
                  _buildItem(Icons.delete_sweep, "Clean Chat", Colors.orangeAccent, () {
                    Navigator.pop(context);
                    onClearChat();
                  }),
                  _buildItem(Icons.open_in_full, "Minimize", Colors.green, () {
                    Navigator.pop(context);
                    onMinimize();
                  }),
                  _buildItem(Icons.logout, "Exit", Colors.redAccent, () {
                    Navigator.pop(context);
                    _showExitDialog(context, onLeave);
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static void _handleFeaturePurchase(BuildContext context, String roomId, String featureType, Function onAllowed) async {
    String myUid = _auth.currentUser?.uid ?? "";
    var roomRef = _firestore.collection('rooms').doc(roomId);
    var userRef = _firestore.collection('users').doc(myUid);

    var roomSnap = await roomRef.get();
    if (!roomSnap.exists) return;
    
    var roomData = roomSnap.data();
    var packageData = roomData?[featureType + '_package'];
    bool hasActivePackage = false;

    if (packageData != null && packageData['expiry'] != null) {
      DateTime expiry = (packageData['expiry'] as Timestamp).toDate();
      if (DateTime.now().isBefore(expiry)) {
        hasActivePackage = true;
      }
    }

    if (hasActivePackage) {
      if (featureType == "room_lock") {
        _showPasswordDialog(context, onAllowed);
      } else {
        onAllowed();
      }
    } else {
      _showPurchaseDialog(context, (int hours, int diamonds) async {
        var userDoc = await userRef.get();
        int myDiamonds = userDoc.data()?['diamonds'] ?? 0;

        if (myDiamonds >= diamonds) {
          await userRef.update({'diamonds': myDiamonds - diamonds});
          await roomRef.update({
            featureType + '_package': {
              'expiry': Timestamp.fromDate(DateTime.now().add(Duration(hours: hours))),
              'boughtAt': FieldValue.serverTimestamp(),
            }
          });
          
          if (featureType == "room_lock") {
            _showPasswordDialog(context, onAllowed);
          } else {
            onAllowed();
          }
        } else {
          _showMessage(context, "আপনার পর্যাপ্ত ডায়মন্ড নেই!");
        }
      });
    }
  }

  static void _showPasswordDialog(BuildContext context, Function onConfirm) {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Set Room Password", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter 4 digit code", 
            hintStyle: TextStyle(color: Colors.white24),
            counterStyle: TextStyle(color: Colors.white60)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("Cancel")),
          TextButton(onPressed: () {
            if (passController.text.length == 4) {
              Navigator.pop(dContext);
              onConfirm();
            }
          }, child: const Text("Set")),
        ],
      ),
    );
  }

  static void _showPurchaseDialog(BuildContext context, Function(int, int) onBuy) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("ফিচারটি চালু করুন", style: TextStyle(color: Colors.white)),
        content: const Text("আপনার কোনো সক্রিয় প্যাকেজ নেই।", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () { Navigator.pop(dContext); onBuy(24, 200); }, child: const Text("২৪ ঘণ্টা (২০০ 💎)")),
          TextButton(onPressed: () { Navigator.pop(dContext); onBuy(720, 3500); }, child: const Text("১ মাস (৩৫০০ 💎)")),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Widget _buildItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  static void _showExitDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Exit Room?", style: TextStyle(color: Colors.white)),
        content: const Text("আপনি কি রুম থেকে বের হতে চান?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dContext), child: const Text("না")),
          TextButton(onPressed: () { Navigator.pop(dContext); onConfirm(); }, child: const Text("হ্যাঁ", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}*/
