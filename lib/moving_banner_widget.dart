import 'package:flutter/material.dart';
import 'package:pagla_chat/room_top_gifters_banner.dart';

class MovingBannerWidget extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> roomData;

  const MovingBannerWidget({super.key, required this.roomId, required this.roomData});

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
      double screenHeight = MediaQuery.of(context).size.height;
      // ব্লাস্ট বক্সের ঠিক বাম পাশে ডিফল্ট পজিশন
      bannerPosition = Offset(screenWidth - 400, screenHeight - 300);
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