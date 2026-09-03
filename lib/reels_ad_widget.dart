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

  // প্রথমে টেস্ট আইডি দিয়ে কনফার্ম করো যে অ্যাড শো করছে কিনা। 
  // ঠিকমতো কাজ করলে তোমার আসল আইডি বসাবে: 'ca-app-pub-3310579844012244/8050827477'
  final String _adUnitId = 'ca-app-pub-3310579844012244/8050827477'; 

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Reels Native Ad loaded successfully.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Reels Native Ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _nativeAd = null;
            });
          }
        },
      ),
      request: const AdRequest(),
      factoryId: 'listTile',
    );

    _nativeAd!.load();
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