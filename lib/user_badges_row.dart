import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class UserBadgesRow extends StatelessWidget {
  final String userId; // ইউজারের আইডি বা ডকুমেন্ট আইডি

  const UserBadgesRow({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // ইউজার আইডি খালি থাকলে ফিক্সড হাইটের খালি জায়গা রিটার্ন করবে যাতে লেআউট না কাঁপে
    if (userId.isEmpty) {
      return const SizedBox(height: 78); // দুটি সারি হওয়ায় উচ্চতা বাড়িয়ে এডজাস্ট করা হলো
    }

    return Center(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data() == null) {
            return const SizedBox.shrink();
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // পুরাতন ডাটাবেজ থেকে চেক করার লজিক
          bool isOfficial = (userData['isOfficial'] == true) || (userData['role'] == 'official');
          bool isSuperAdmin = (userData['isSuperAdmin'] == true) || (userData['role'] == 'super_admin');
          bool isAgency = (userData['isAgency'] == true) || (userData['isAgent'] == true);

          // নতুন ব্যাজগুলোর জন্য ডেটা চেক
          bool isSuperHost = userData['isSuperHost'] == true;
          bool isLovelyCouple = userData['isMarried'] == true || userData['lovelyCouple'] == true;
          
          // টিম প্যানেল নাম বা স্ট্যাটাস চেক
          String teamPanelName = '';
          if (userData['teamPanel'] != null && userData['teamPanel'] is Map) {
            teamPanelName = userData['teamPanel']['panelName'] ?? '';
          } else if (userData['teamPanelName'] != null) {
            teamPanelName = userData['teamPanelName'].toString();
          }
          bool hasTeamPanel = teamPanelName.isNotEmpty;

          bool hasTopRow = isOfficial || isSuperAdmin || isAgency;
          bool hasBottomRow = isSuperHost || isLovelyCouple || hasTeamPanel;

          // কোনো ব্যাজ না থাকলে কিছু দেখাবে না
          if (!hasTopRow && !hasBottomRow) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ১. প্রথম সারি (পুরাতন ৩টি ভেইজ)
                if (hasTopRow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (isOfficial) ...[
                            _buildShimmerBadge("OFFICIAL", const [Colors.amber, Colors.orangeAccent]),
                          ],
                          if (isOfficial && (isSuperAdmin || isAgency)) const SizedBox(width: 8),

                          if (isSuperAdmin) ...[
                            _buildShimmerBadge("SUPER ADMIN", const [Colors.purpleAccent, Colors.pinkAccent]),
                          ],
                          if (isSuperAdmin && isAgency) const SizedBox(width: 8),

                          if (isAgency) ...[
                            _buildShimmerBadge("AGENCY", const [Colors.cyanAccent, Colors.blueAccent]),
                          ],
                        ],
                      ),
                    ),
                  ),

                // ২. দ্বিতীয় সারি (নতুন ৩টি ভেইজ - সুপার হোস্ট, লাভলি কাপল, টিম প্যানেল)
                if (hasBottomRow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (isSuperHost) ...[
                          _buildShimmerBadge("SUPER HOST", const [Colors.greenAccent, Colors.tealAccent]),
                        ],
                        if (isSuperHost && (isLovelyCouple || hasTeamPanel)) const SizedBox(width: 8),

                        if (isLovelyCouple) ...[
                          _buildShimmerBadge("LOVELY COUPLE", const [Colors.pink, Colors.redAccent]),
                        ],
                        if (isLovelyCouple && hasTeamPanel) const SizedBox(width: 8),

                        if (hasTeamPanel) ...[
                          _buildShimmerBadge(teamPanelName.toUpperCase(), const [Colors.amberAccent, Colors.yellow]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // জিক-জিক (Shimmer) এবং গোল্ডেন বর্ডার সহ ব্যাজ ডিজাইন উইজেট
  Widget _buildShimmerBadge(String title, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700), // গোল্ডেন বর্ডার
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: gradientColors[0],
        highlightColor: Colors.white,
        period: const Duration(milliseconds: 1500),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.0, 
          ),
        ),
      ),
    );
  }
}