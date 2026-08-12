import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniVideoThumbnailPlayer extends StatelessWidget {
  final String videoUrl;
  const MiniVideoThumbnailPlayer({Key? key, required this.videoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: CachedNetworkImage(
        imageUrl: videoUrl,
        fit: BoxFit.cover,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.card_giftcard,
          color: Colors.white24,
        ),
      ),
    );
  }
}