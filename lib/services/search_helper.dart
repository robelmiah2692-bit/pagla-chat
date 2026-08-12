import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pagla_chat/profile_page.dart';
import 'package:pagla_chat/screens/voice_room.dart';

class SearchHelper {
  static void showSearchDialog(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        // ভেরিয়েবলগুলো এখানে ডিক্লেয়ার করতে হবে যাতে setState হলেও ডাটা রিসেট না হয়ে যায়
        bool isLoading = false;
        Map<String, dynamic>? searchResultData;
        String resultType = ""; // 'room' অথবা 'user'
        String errorMessage = "";

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> performSearch(String query) async {
              debugPrint("🔍 [SEARCH_DEBUG] Search initiated with query: '$query'");
              if (query.isEmpty) {
                debugPrint("⚠️ [SEARCH_DEBUG] Query is empty, skipping search.");
                return;
              }

              setState(() {
                isLoading = true;
                searchResultData = null;
                errorMessage = "";
              });

              try {
                // ১. প্রথমে শুধু 'rooms' কালেকশনে চেক করা হবে (রুম আইডি বা ডকুমেন্ট আইডি দিয়ে)
                debugPrint("🔎 [SEARCH_DEBUG] Checking in 'rooms' collection...");
                
                var roomDoc = await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(query)
                    .get();

                if (roomDoc.exists && roomDoc.data() != null) {
                  debugPrint("✅ [SEARCH_DEBUG] Found room by Document ID in 'rooms'!");
                  var data = roomDoc.data()!;
                  data['roomId'] = data['roomId']?.toString() ?? query;
                  setState(() {
                    searchResultData = data;
                    resultType = 'room';
                    isLoading = false;
                  });
                  return;
                }

                var roomQuery = await FirebaseFirestore.instance
                    .collection('rooms')
                    .where('roomId', isEqualTo: query)
                    .limit(1)
                    .get();

                if (roomQuery.docs.isNotEmpty) {
                  debugPrint("✅ [SEARCH_DEBUG] Found room by 'roomId' field in 'rooms'!");
                  var data = roomQuery.docs.first.data();
                  data['roomId'] = data['roomId']?.toString() ?? query;
                  setState(() {
                    searchResultData = data;
                    resultType = 'room';
                    isLoading = false;
                  });
                  return;
                }

                // ২. রুম না পাওয়া গেলে এবার শুধু 'users' কালেকশনে চেক করা হবে
                debugPrint("🔎 [SEARCH_DEBUG] Room not found. Checking in 'users' collection...");

                var userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(query)
                    .get();

                if (userDoc.exists && userDoc.data() != null) {
                  debugPrint("✅ [SEARCH_DEBUG] Found user by Document ID in 'users'!");
                  var data = userDoc.data()!;
                  data['uID'] = data['uID']?.toString() ?? query;
                  setState(() {
                    searchResultData = data;
                    resultType = 'user';
                    isLoading = false;
                  });
                  return;
                }

                var userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('uID', isEqualTo: query)
                    .limit(1)
                    .get();

                if (userQuery.docs.isNotEmpty) {
                  debugPrint("✅ [SEARCH_DEBUG] Found user by 'uID' field in 'users'!");
                  var data = userQuery.docs.first.data();
                  data['uID'] = data['uID']?.toString() ?? query;
                  setState(() {
                    searchResultData = data;
                    resultType = 'user';
                    isLoading = false;
                  });
                  return;
                }

                // ৩. কোথাও না পাওয়া গেলে
                debugPrint("❌ [SEARCH_DEBUG] No matching room or user found for query: $query");
                setState(() {
                  errorMessage = "No room or user found with this ID!";
                  isLoading = false;
                });

              } catch (e) {
                debugPrint("❌ [SEARCH_DEBUG] Search error occurred: $e");
                setState(() {
                  errorMessage = "Error: $e";
                  isLoading = false;
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0F0C29),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Search User or Room ID",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter uID or Room ID",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // সার্চ বাটন
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        String query = searchController.text.trim();
                        debugPrint("🔘 [SEARCH_DEBUG] Search button clicked! Query text: '$query'");
                        if (query.isNotEmpty) {
                          performSearch(query);
                        }
                      },
                      child: const Text("Search", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 15),

                    // লোডিং ইন্ডিকেটর
                    if (isLoading)
                      const CircularProgressIndicator(color: Colors.cyanAccent),

                    // এরর মেসেজ
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),

                    // সার্চ রেজাল্ট কার্ড আকারে প্রদর্শন
                    if (searchResultData != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          debugPrint("👆 [SEARCH_DEBUG] Search result card clicked. Type: $resultType");
                          Navigator.pop(context);
                          if (resultType == 'room') {
                            String rId = searchResultData!['roomId']?.toString() ?? searchController.text.trim();
                            String oId = searchResultData!['ownerId']?.toString() ?? '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VoiceRoom(roomId: rId, ownerId: oId),
                              ),
                            );
                          } else if (resultType == 'user') {
                            String uId = searchResultData!['uID']?.toString() ?? searchController.text.trim();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(userId: uId),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
                          ),
                          child: Row(
                            children: [
                              // প্রোফাইল বা রুম পিকচার
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: resultType == 'room' 
                                      ? (searchResultData!['roomImage'] ?? searchResultData!['ownerPic'] ?? '')
                                      : (searchResultData!['profilePic'] ?? ''),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.white12),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ডিটেইলস
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resultType == 'room' 
                                          ? (searchResultData!['roomName'] ?? 'Live Room')
                                          : (searchResultData!['name'] ?? 'Pagla User'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resultType == 'room' 
                                          ? "Room ID: ${searchResultData!['roomId']}"
                                          : "uID: ${searchResultData!['uID']}",
                                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}