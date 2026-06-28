import 'package:flutter/material.dart';

class AgencyBadgeWidget extends StatelessWidget {
  final bool isAgent;
  final String imageUrl;

  const AgencyBadgeWidget({
    super.key,
    required this.isAgent,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAgent) {
      return const SizedBox.shrink();
    }

    return Container(
      // জেন্ডার ব্যাজের সাথে প্যাডিং হুবহু এক রাখা হয়েছে
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        // বর্ডার কালার ও উইডথ আপনার রিকোয়েস্ট অনুযায়ী সেট করা হয়েছে
        border: Border.all(
          color: const Color.fromARGB(255, 239, 250, 38).withOpacity(0.5), 
          width: 1.2,
        ),
      ),
      // জেন্ডার ব্যাজের সাইজ অনুযায়ী হাইট ও উইডথ
      child: SizedBox(
        width: 32, 
        height: 18, 
        child: Image.network(
          imageUrl,
          fit: BoxFit.fill, // ইমেজটি টেনে পুরো বক্স পূর্ণ করবে
          filterQuality: FilterQuality.high, // ইমেজ শার্প দেখানোর জন্য
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(
                Icons.business_center, 
                color: Color.fromARGB(255, 112, 212, 248), 
                size: 18,
              ),
        ),
      ),
    );
  }
}