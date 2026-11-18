import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserBadgesRow extends StatelessWidget {
  final String userId; // ইউজারের আইডি বা ডকুমেন্ট আইডি

  const UserBadgesRow({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // ইউজার আইডি খালি থাকলে কোনো জায়গা নেবে না (0 size)
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Center(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(const GetOptions(source: Source.serverAndCache)),
        builder: (context, snapshot) {
          // লোডিং বা ডেটা না থাকলে কোনো জায়গা বা ফাকা স্পেস নেবে না
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const SizedBox.shrink();
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // পুরাতন ডাটাবেজ থেকে চেক করার লজিক
          bool isOfficial = (userData['isOfficial'] == true) ||
              (userData['role'] == 'official');
          bool isSuperAdmin = (userData['isSuperAdmin'] == true) ||
              (userData['role'] == 'super_admin');
          bool isAgency =
              (userData['isAgency'] == true) || (userData['isAgent'] == true);

          // নতুন ও ভলেন্টিয়ার ব্যাজগুলোর জন্য ডেটা চেক
          bool isSuperHost = userData['isSuperHost'] == true;
          bool isVolunteer = (userData['isVolunteer'] == true) ||
              (userData['role'] == 'volunteer');
          bool isLovelyCouple =
              userData['isMarried'] == true || userData['lovelyCouple'] == true;

          // টিম প্যানেল নাম বা স্ট্যাটাস চেক
          String teamPanelName = '';
          if (userData['teamPanel'] != null && userData['teamPanel'] is Map) {
            teamPanelName = userData['teamPanel']['panelName'] ?? '';
          } else if (userData['teamPanelName'] != null) {
            teamPanelName = userData['teamPanelName'].toString();
          }
          bool hasTeamPanel = teamPanelName.isNotEmpty;

          bool hasTopRow = isOfficial || isSuperAdmin || isAgency;
          bool hasBottomRow =
              isSuperHost || isVolunteer || isLovelyCouple || hasTeamPanel;

          // কোনো ব্যাজ না থাকলে ফিক্সড হাইট বাদ দিয়ে একদম শূন্য সাইজ রিটার্ন করবে, ফলে নিচের বার উপরে উঠে যাবে
          if (!hasTopRow && !hasBottomRow) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ১. প্রথম সারি (অফিশিয়াল, সুপার অ্যাডমিন, এজেন্সি - কাস্টম ইমেজ ব্যাজ)
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
                            _buildCustomImageBadge(
                                "assets/images/official_badge.webp"), // 👈 আপনার অফিশিয়াল ব্যাজ ইমেজ পাথ
                          ],
                          if (isOfficial && (isSuperAdmin || isAgency))
                            const SizedBox(width: 8),
                          if (isSuperAdmin) ...[
                            _buildCustomImageBadge(
                                "assets/images/superadmin_badge.webp"), // 👈 সুপার অ্যাডমিন ব্যাজ
                          ],
                          if (isSuperAdmin && isAgency)
                            const SizedBox(width: 8),
                          if (isAgency) ...[
                            _buildCustomImageBadge(
                                "assets/images/agency_badge.webp"), // 👈 এজেন্সি ব্যাজ
                          ],
                        ],
                      ),
                    ),
                  ),

                // ২. দ্বিতীয় সারি (সুপার হোস্ট, ভলেন্টিয়ার, লাভলি কাপল এবং টিম প্যানেল)
                if (hasBottomRow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (isSuperHost) ...[
                          _buildCustomImageBadge(
                              "assets/images/superhost_badge.webp"), // 👈 সুপার হোস্ট ব্যাজ
                        ],
                        if (isSuperHost &&
                            (isVolunteer || isLovelyCouple || hasTeamPanel))
                          const SizedBox(width: 8),
                        if (isVolunteer) ...[
                          _buildCustomImageBadge(
                              "assets/images/volunteer_badge.webp"), // 👈 ভলেন্টিয়ার ব্যাজ
                        ],
                        if (isVolunteer && (isLovelyCouple || hasTeamPanel))
                          const SizedBox(width: 8),
                        if (isLovelyCouple) ...[
                          _buildCustomImageBadge(
                              "assets/images/lovelycouple_badge.webp"), // 👈 লাভলি কাপল ব্যাজ
                        ],
                        if (isLovelyCouple && hasTeamPanel)
                          const SizedBox(width: 8),
                        if (hasTeamPanel) ...[
                          // 👈 এখানে শিমার ব্যাজের বদলে কাস্টম ইমেজ ব্যাকগ্রাউন্ডসহ টিম প্যানেল ব্যাজ কল করা হলো
                          _buildTeamPanelBadge(teamPanelName.toUpperCase()),
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

  Widget _buildCustomImageBadge(String assetPath, {double height = 30}) {
    return Container(
      height: height,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTeamPanelBadge(String teamName) {
    return SizedBox(
      height: 32, // অন্যান্য ব্যাজের সাইজের সাথে মিল রেখে হাইট
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ১. ব্যাকগ্রাউন্ডে আপনার কাস্টম খালি ব্যাজ ইমেজ
          Image.asset(
            "assets/images/blank_badge.webp", // 👈 আপনার টিম প্যানেলের খালি ডিজাইনের ইমেজ পাথ
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
          // ২. ইমেজের ওপর ডাইনামিক টিম প্যানেলের নামটি বসানোর জন্য
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal:
                    16.0), // ইমেজ অনুযায়ী টেক্সটের জায়গা অ্যাডজাস্ট করার জন্য
            child: Text(
              teamName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 6.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
