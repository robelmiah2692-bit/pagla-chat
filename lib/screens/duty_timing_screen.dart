import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DutyTimingScreen extends StatelessWidget {
  final String userDocId;

  const DutyTimingScreen({Key? key, required this.userDocId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "My Duty Timing & Live Ranking",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userDocId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No data found!",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          int totalMinutes = userData['totalRoomMinutes'] ?? 0;
          double totalHours = (userData['totalRoomHours'] ?? 0.0).toDouble();
          String lastRoom = userData['lastActiveRoom'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ১. টপ ব্যানার
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.trending_up, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text(
                        "Staff Duty Performance",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Keep active in rooms to boost your live rank & timing!",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ২. ঘণ্টা এবং মিনিটের কার্ড
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Hours",
                        value: "$totalHours",
                        unit: "Hours",
                        icon: Icons.hourglass_top,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Minutes",
                        value: "$totalMinutes",
                        unit: "Minutes",
                        icon: Icons.access_time_filled,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ৩. 🔥 লাইভ রেংকিং ও গ্রোথ গ্রাফ সেকশন (আপনার ছবির মতো ডিজাইন)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Live Growth Ranking",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  "Live Active",
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your progress goes up as your total minutes ($totalMinutes mins) increase.",
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 20),
                      
                      // ডাইনামিক গ্রাফ উইজেট
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: LiveRankChartPainter(progressMinutes: totalMinutes.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ৪. শেষ রুমের আইডি কার্ড
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Colors.greenAccent, size: 28),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Last Active Room ID",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lastRoom,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ৫. ফুটার নোট
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "💡 Note: Duty time and ranking progress are automatically updated in real-time.",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🔥 লাইভ গ্রাফ পেইন্টার ক্লাস (যা ইউজারের মিনিটের ওপর ভিত্তি করে ওপরের দিকে উঠবে)
class LiveRankChartPainter extends CustomPainter {
  final double progressMinutes;

  LiveRankChartPainter({required this.progressMinutes});

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.cyanAccent.withOpacity(0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    Paint gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    // ব্যাকগ্রাউন্ড গ্রিড লাইন আঁকা
    for (int i = 1; i < 4; i++) {
      double y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ডাইনামিক গ্রাফ পয়েন্ট তৈরি (মিনিট বাড়লে গ্রাফের হাইট ও কার্ভ ওপরের দিকে উঠবে)
    Path path = Path();
    Path fillPath = Path();

    double normalizedHeight = (progressMinutes % 100) / 100; // প্রগ্রেসের ওপর ভিত্তি করে ওঠানামা করবে
    double h1 = size.height * (0.8 - (normalizedHeight * 0.2));
    double h2 = size.height * (0.6 - (normalizedHeight * 0.3));
    double h3 = size.height * (0.4 - (normalizedHeight * 0.2));
    double h4 = size.height * (0.2 + (0.3 * (1 - normalizedHeight)));

    path.moveTo(0, size.height * 0.7);
    path.cubicTo(size.width * 0.25, h1, size.width * 0.5, h2, size.width * 0.75, h3);
    path.cubicTo(size.width * 0.85, h3, size.width * 0.9, h4, size.width, h4);

    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // কার্ভের শেষ প্রান্তে একটি উজ্জ্বল লাইভ পয়েন্ট বা ডট আঁকা
    Paint dotPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width, h4), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}