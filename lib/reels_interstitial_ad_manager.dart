import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ReelsInterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;

  // আপনার তৈরি করা ইন্টার্সটিশিয়াল অ্যাড ইউনিট আইডি
  static const String _adUnitId = 'ca-app-pub-3310579844012244/1119523396';

  // অ্যাড লোড করার মেথড
  static void loadAd() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint('Reels Interstitial Ad loaded successfully.');
          
          // অ্যাড ক্লোড বা ফেল হলে মেমোরি থেকে ক্লিয়ার করে আবার লোড করার জন্য সেটআপ
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              loadAd(); // পরবর্তী বারের জন্য নতুন অ্যাড প্রি-লোড করে রাখা
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Reels Interstitial Ad failed to load: $error');
          _isAdLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  // অ্যাড শো করার মেথড
  static void showAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdLoaded = false;
    } else {
      debugPrint('Interstitial Ad is not ready yet.');
      loadAd(); // যদি লোড না থাকে তবে ব্যাকগ্রাউন্ডে লোড কল করে রাখা
    }
  }
}