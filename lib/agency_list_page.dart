import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'package:pagla_chat/profile_page.dart';


class AgencyListPage extends StatefulWidget {
  const AgencyListPage({Key? key}) : super(key: key);

  @override
  State<AgencyListPage> createState() => _AgencyListPageState();
}

class _AgencyListPageState extends State<AgencyListPage> {
  // ক্যাশিংয়ের জন্য ভেরিয়েবল
  static List<Map<String, dynamic>>? _cachedAgentList;
  static DateTime? _lastFetchTime;
  bool _isLoading = false;

  // কার্ডের চমৎকার ডিজাইনের জন্য রেন্ডম কালার জেনারেটর
  Color _getRandomColor() {
    final Random random = Random();
    List<Color> colorList = [
      Colors.blueAccent,
      Colors.purpleAccent.shade700,
      Colors.cyan.shade700,
      Colors.indigoAccent,
      Colors.deepPurple,
    ];
    return colorList[random.nextInt(colorList.length)];
  }

  @override
  void initState() {
    super.initState();
    // প্রথমবার ক্যাশ না থাকলে ডাটা ফেচ করা হবে
    if (_cachedAgentList == null) {
      _fetchAgentsData();
    }
  }

  // ফায়ারবেজ থেকে ডাটা এনে ক্যাশ করে রাখার ফাংশন (ক্যাশিং লজিক)
  Future<void> _fetchAgentsData({bool forceRefresh = false}) async {
    // যদি ক্যাশ ডাটা থাকে এবং ২ মিনিটের কম সময় হয়, তবে বারবার ডাটাবেজে কল করবে না (ক্যাশ দেখাবে)
    if (!forceRefresh && _cachedAgentList != null && _lastFetchTime != null) {
      if (DateTime.now().difference(_lastFetchTime!).inMinutes < 2) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isAgent', isEqualTo: true)
          .get();

      var agents = userSnapshot.docs;
      List<Map<String, dynamic>> agentList = [];

      for (var doc in agents) {
        var agentData = doc.data();
        String uId = doc.id;
        String name = agentData['name'] ?? agentData['userName'] ?? "Agent User";
        String profilePic = agentData['profilePic'] ?? agentData['photoUrl'] ?? "";

        // ডায়মন্ড হিস্ট্রি থেকে সফল ট্রানজেকশন কাউন্ট আনা
        var txSnapshot = await FirebaseFirestore.instance
            .collection('diamond_history')
            .where('senderId', isEqualTo: uId)
            .get();

        int rechargeCount = txSnapshot.docs.length;

        agentList.add({
          'uId': uId,
          'name': name,
          'profilePic': profilePic,
          'rechargeCount': rechargeCount,
        });
      }

      // যার ট্রানজেকশন বেশি সে সবার উপরে থাকবে (Descending Sort)
      agentList.sort((a, b) => b['rechargeCount'].compareTo(a['rechargeCount']));

      // ক্যাশে সেভ করে রাখা
      _cachedAgentList = agentList;
      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint("❌ এজেন্ট ডাটা লোড করতে সমস্যা হয়েছে: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading && _cachedAgentList == null
          ? const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 6, 250, 209)),
            )
          : _cachedAgentList == null || _cachedAgentList!.isEmpty
              ? const Center(
                  child: Text(
                    "কোনো এজেন্ট পাওয়া যায়নি!",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchAgentsData(forceRefresh: true),
                  color: const Color.fromARGB(255, 6, 250, 209),
                  backgroundColor: Colors.grey[900],
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cachedAgentList!.length,
                    itemBuilder: (context, index) {
                      var agent = _cachedAgentList![index];
                      String uId = agent['uId'];
                      String name = agent['name'];
                      String profilePic = agent['profilePic'];
                      int rechargeCount = agent['rechargeCount'];

                      Color cardColor = _getRandomColor();
                      Color randomBorderColor = _getRandomColor();

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cardColor.withOpacity(0.6), Colors.grey[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          // প্রফাইল পিকচারে ক্লিক করলে প্রোফাইলে যাওয়ার সিস্টেম
                          leading: GestureDetector(
                            onTap: () => _navigateToProfile(context, uId),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: randomBorderColor,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: profilePic.isNotEmpty
                                    ? CachedNetworkImageProvider(profilePic)
                                    : null,
                                child: profilePic.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("uID: $uId", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                "Successful Recharges: $rechargeCount",
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 6, 250, 209),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                          // পুরো কার্ডে ক্লিক করলে প্রোফাইলে যাওয়ার সিস্টেম
                          onTap: () => _navigateToProfile(context, uId),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // প্রোফাইলে নেভিগেট করার কার্যকরী ফাংশন
  Future<void> _navigateToProfile(BuildContext context, String uId) async {
    String finalIdToPass = uId;
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('authUID', isEqualTo: uId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        finalIdToPass = userQuery.docs.first.data()['uID']?.toString() ?? userQuery.docs.first.id;
      }
    } catch (e) {
      debugPrint("❌ Users কালেকশন থেকে uID লোড করতে ব্যর্থ: $e");
    }

    if (!context.mounted) return;

    // প্রোফাইল পেজে নেভিগেশন (আনকমেন্ট করা হয়েছে)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: finalIdToPass), // আপনার ProfilePage کلاس এখানে কাজ করবে
      ),
    );
  }
}