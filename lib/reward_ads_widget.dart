import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardAdsBoxWidget extends StatefulWidget {
  const RewardAdsBoxWidget({super.key});

  @override
  State<RewardAdsBoxWidget> createState() => _RewardAdsBoxWidgetState();
}

class _RewardAdsBoxWidgetState extends State<RewardAdsBoxWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    print("🔄 Loading Rewarded Ad...");
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3310579844012244/1184656900', 
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ Rewarded Ad Loaded Successfully!");
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print("ℹ️ Ad dismissed by user.");
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print("❌ Failed to show ad: $error");
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print("❌ Rewarded Ad Failed to Load. Error Code: ${error.code}, Message: ${error.message}");
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _handleWatchAd(BuildContext context) async {
    print("📦 Treasure Box Clicked!");
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User not logged in!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentReference? docRef;

      // ১. প্রথমে 'uID' ফিল্ড দিয়ে খোঁজা
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('uID', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        docRef = query.docs.first.reference;
      } else {
        // ২. না পেলে ছোটহাতের 'uid' ফিল্ড দিয়ে খোঁজা
        var queryUid = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (queryUid.docs.isNotEmpty) {
          docRef = queryUid.docs.first.reference;
        } else {
          // ৩. না পেলে 'ownerId' ফিল্ড দিয়ে খোঁজা
          var queryOwner = await FirebaseFirestore.instance
              .collection('users')
              .where('ownerId', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (queryOwner.docs.isNotEmpty) {
            docRef = queryOwner.docs.first.reference;
          }
        }
      }

      if (docRef == null) {
        print("❌ User document does not exist in Firestore!");
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User document not found in database!")),
          );
        }
        return;
      }

      final snapshot = await docRef.get();
      final data = snapshot.data() as Map<String, dynamic>?;

      int adsWatchedToday = 0;
      String lastAdDate = '';
      String todayDate = DateTime.now().toIso8601String().split('T')[0];

      if (data != null) {
        lastAdDate = data['last_ad_date'] ?? '';
        if (lastAdDate == todayDate) {
          adsWatchedToday = data['ads_watched_today'] ?? 0;
        } else {
          adsWatchedToday = 0;
        }
      }

      if (adsWatchedToday >= 4) {
        print("⚠️ User already watched 4 ads today.");
        setState(() => _isLoading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have already watched 4 ads today!")),
          );
        }
        return;
      }

      if (!_isAdLoaded || _rewardedAd == null) {
        print("⚠️ Ad was not ready. Trying to load on demand...");
        RewardedAd.load(
          adUnitId: 'ca-app-pub-3310579844012244/1184656900',
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              print("✅ On-demand Ad Loaded!");
              setState(() {
                _rewardedAd = ad;
                _isAdLoaded = true;
                _isLoading = false;
              });
              _showAd(docRef!, adsWatchedToday, todayDate, context);
            },
            onAdFailedToLoad: (error) {
              print("❌ On-demand Ad Failed to Load: ${error.message}");
              setState(() => _isLoading = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Ad failed to load: ${error.message}")),
                );
              }
            },
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showAd(docRef, adsWatchedToday, todayDate, context);
      }

    } catch (e) {
      print("❌ Exception caught in _handleWatchAd: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAd(DocumentReference userDocRef, int adsWatchedToday, String todayDate, BuildContext context) {
    if (_rewardedAd != null) {
      print("🎬 Showing Rewarded Ad now...");
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          print("🎁 User earned reward! Adding 50 diamonds...");
          await userDocRef.update({
            'diamonds': FieldValue.increment(50),
            'ads_watched_today': adsWatchedToday + 1,
            'last_ad_date': todayDate,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("50 Diamonds added to your account!")),
            );
          }
        },
      );
      _rewardedAd = null;
      _isAdLoaded = false;
      _loadRewardedAd();
    } else {
      print("❌ _rewardedAd is null when trying to show!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.04).animate(_controller),
      child: GestureDetector(
        onTap: _isLoading ? null : () => _handleWatchAd(context),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFD32F2F), Color(0xFFB71C1C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.7),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 6,
                child: Container(
                  width: 38,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.white, blurRadius: 4),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.fiber_manual_record,
                color: Color(0xFFFFD700),
                size: 26,
              ),
              const Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFF8D6E63),
                size: 14,
              ),
              if (_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.amberAccent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}