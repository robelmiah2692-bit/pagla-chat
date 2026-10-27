import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      if (widget.imageUrl.startsWith('http')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Downloading image...")),
          );
        }

        final HttpClient httpClient = HttpClient();
        final HttpClientRequest request = await httpClient.getUrl(Uri.parse(widget.imageUrl));
        final HttpClientResponse response = await request.close();
        final Uint8List bytes = await consolidateHttpClientResponseBytes(response);

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(bytes);

        await Gal.putImage(file.path);
      } else {
        // যদি লোকাল ফাইল হয় তবে সরাসরি গ্যালারিতে সেভ হবে
        await Gal.putImage(widget.imageUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image Saved Successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHttp = widget.imageUrl.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadImage,
            tooltip: "Download Image",
          ),
        ],
      ),
      body: GestureDetector(
        onLongPress: _downloadImage,
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: isHttp
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                    errorWidget: (context, error, stackTrace) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 60),
                        SizedBox(height: 10),
                        Text("Failed to load image", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  )
                : Image.file(
                    File(widget.imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 60),
                        SizedBox(height: 10),
                        Text("Failed to load local image", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}