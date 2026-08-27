import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DiamondGridItem extends StatefulWidget {
  final String display;
  final String price;
  final VoidCallback onTap;

  const DiamondGridItem({
    Key? key,
    required this.display,
    required this.price,
    required this.onTap,
  }) : super(key: key);

  @override
  State<DiamondGridItem> createState() => _DiamondGridItemState();
}

class _DiamondGridItemState extends State<DiamondGridItem>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // বর্ডার এবং গ্লো অ্যানিমেশনের জন্য কন্ট্রোলার
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // শিমার সাইনিং অনবরত চালানোর জন্য আলাদা কন্ট্রোলার
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String designUrl =
        "https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/main/officialall/daimondprice.jpg";

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // কার্ডের পেছন থেকে গ্লোয়িং এবং কালার চেঞ্জিং বর্ডার অ্যানিমেশন
              boxShadow: [
                BoxShadow(
                  color: Colors.amber
                      .withOpacity(0.3 + (_borderController.value * 0.4)),
                  blurRadius: 10 + (_borderController.value * 10),
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Color.lerp(Colors.amber.shade700, Colors.cyanAccent,
                        _borderController.value) ??
                    Colors.amber,
                width: 2.5,
              ),
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: designUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.purple.shade900,
              child: Center(
                child: Text(widget.display,
                    style: const TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.bold)),
              ),
            ),
            imageBuilder: (context, imageProvider) => Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // কাস্টম ইনফিনিট শিমার সাইনিং ইফেক্ট (যা কখনো থামবে না)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment(
                        _shimmerController.value * 3.0 - 1.5,
                        0.0,
                      ),
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.35),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.diamond,
                        color: Colors.blueAccent, size: 26),
                    const SizedBox(height: 5),
                    Text(widget.display,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(widget.price,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.purple.shade900,
              child: const Center(child: Icon(Icons.error, color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}
