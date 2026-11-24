import 'package:flutter/material.dart';
import 'package:pagla_chat/room_top_gifters_banner.dart';

class MovingBannerWidget extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const MovingBannerWidget({
    super.key,
    required this.roomId,
    required this.roomData,
  });

  @override
  State<MovingBannerWidget> createState() => _MovingBannerWidgetState();
}

class _MovingBannerWidgetState extends State<MovingBannerWidget> {
  Offset bannerPosition = Offset.zero;
  bool _isPositionInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPositionInitialized) {
      double screenWidth = MediaQuery.of(context).size.width;

      const double bannerWidth = 240;     // ব্যানারের আনুমানিক প্রস্থ (মাঝখানে রাখার জন্য)
      const double topOffset = 85;        // 👈 ওপরে-নিচে নিতে (বাড়ালে নিচে, কমালে ওপরে)
      const double horizontalOffset = 0;   // 👈 ডানে-বামে নিতে (ডানে নিতে +20, বামে নিতে -20)

      double centeredX = ((screenWidth - bannerWidth) / 2) + horizontalOffset;
      if (centeredX < 0) centeredX = 0;

      bannerPosition = Offset(centeredX, topOffset);
      _isPositionInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bannerPosition.dx,
      top: bannerPosition.dy,
      child: Draggable(
        feedback: RoomTopGiftersBanner(
          roomId: widget.roomId,
          roomData: widget.roomData,
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            bannerPosition = details.offset;
          });
        },
        child: RoomTopGiftersBanner(
          roomId: widget.roomId,
          roomData: widget.roomData,
        ),
      ),
    );
  }
}