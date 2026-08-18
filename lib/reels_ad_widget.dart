import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ReelsAdWidget extends StatefulWidget {
  const ReelsAdWidget({super.key});

  @override
  State<ReelsAdWidget> createState() => _ReelsAdWidgetState();
}

class _ReelsAdWidgetState extends State<ReelsAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  // টেস্ট এড ইউনিট আইডি (রিয়েল অ্যাপে পাবলিশ করার সময় আপনার আসল AdMob Native Ad Unit ID বসাবেন)
  final String _adUnitId = 'ca-app-pub-3940256099942544/2247696110'; 

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad load failed (Reels): $error');
        },
      ),
      request: const AdRequest(),
      // কাস্টম টেমপ্লেট বা স্টাইল যা রিলসের কালো থিমের সাথে মানানসই
      factoryId: 'listTile', 
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: _isAdLoaded && _nativeAd != null
          ? SizedBox(
              height: 350,
              width: MediaQuery.of(context).size.width * 0.9,
              child: AdWidget(ad: _nativeAd!),
            )
          : const Center(
              child: Text(
                "Sponsored Ad...",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
    );
  }
}