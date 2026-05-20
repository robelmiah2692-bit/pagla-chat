import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'soulmate_service.dart'; // আপনার সার্ভিস ফাইলের পাথ দিন

class SoulmateDetailPage extends StatelessWidget {
  final Map<String, dynamic> soulmateData;

  const SoulmateDetailPage({Key? key, required this.soulmateData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ১. আপনার পুরাতন লেভেল লজিক হুবহু এক রাখা হয়েছে
    int totalGift = soulmateData['totalGift'] ?? 0;
    int level = (totalGift / 5000).floor().clamp(1, 50);
    
    // লেভেল বার প্রোগ্রেস হিসাব (৫০০০ গিফটে ১ লেভেল বার)
    int currentLevelBase = (level - 1) * 5000;
    int currentProgressGifts = totalGift - currentLevelBase;
    double progressPercent = (currentProgressGifts / 5000).clamp(0.0, 1.0);
    if (level >= 50) progressPercent = 1.0;

    // ২. বন্ধুত্বের লাইভ তারিখ ও সময় ফরম্যাট
    String friendshipDate = "Unknown";
    if (soulmateData['createdAt'] != null) {
      Timestamp timestamp = soulmateData['createdAt'];
      friendshipDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
    }

    // ৩. আপনার ডাটা ম্যাপের অরিজিনাল রাস্তা অনুযায়ী পার্টনারের ডাটা রিড
    String partnerId = soulmateData['partnerId'] ?? '';
    String partnerName = soulmateData['partnerName'] ?? 'Unknown';
    String partnerImage = soulmateData['partnerImage'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: const Text("Soulmate Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("✨ Soulmate Lv.$level ✨",
                style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // 👥 দুইজনের নাম ও ছবি পাশাপাশি শো
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 👤 ইউজার নিজে (বাম পাশে)
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[900],
                        child: ClipOval(
                          child: Image.network(
                            "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/femalepic%20(46).jpg",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Arisha",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // 💖 মাঝখানে লাভ আইকন
                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),

                // 👥 পার্টনার (ডান পাশে - অরিজিনাল ডাটা রাস্তা)
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[900],
                        child: ClipOval(
                          child: partnerImage.isEmpty
                              ? const Icon(Icons.person, color: Colors.white, size: 40)
                              : Image.network(
                                  partnerImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 40),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        partnerName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 📊 লাইভ লেভেল প্রোগ্রেস বার (গিফটের সাথে সাথে বাড়বে)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Level Progress (Lv.$level)", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text("$totalGift / ${level * 5000} 💎", style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 12,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🗓️ বন্ধুত্বের লাইভ তারিখ ও সময় সেকশন
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: const Color(0xFF1E1E2F), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.pinkAccent, size: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Start Hart:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(friendshipDate, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // 💔 সম্পর্ক ছিন্ন করার বাটন
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.heart_broken, color: Colors.white),
              label: const Text("End Hart (1500 💎)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _showBreakupDetailPageDialog(context, partnerId),
            ),
          ],
        ),
      ),
    );
  }

  // আপনার অরিজিনাল ডায়ালগ লজিকটি এখানেও যুক্ত করা হলো যাতে এখান থেকেও সম্পর্ক ব্রেক করা যায়
  void _showBreakupDetailPageDialog(BuildContext context, String partnerId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Sure end relationship ?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("End relationship need 1k daimond", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              String response = await SoulmateService().breakRelation(partnerId);
              Navigator.pop(context); // পেজ ক্লোজ করে মেইন প্রোফাইলে ব্যাক করবে
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response), backgroundColor: Colors.pinkAccent));
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}