import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageGalleryScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = isWebOrDesktopCached ? 800.0 : constraints.maxWidth;
                  double maxHeight = isWebOrDesktopCached ? 600.0 : constraints.maxHeight;
                  
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.contain,
                      httpHeaders: const {
                        'Access-Control-Allow-Origin': '*',
                        'Cache-Control': 'max-age=3600',
                        'Accept': 'image/*',
                      },
                      progressIndicatorBuilder: (context, url, downloadProgress) => Center(
                        child: CircularProgressIndicator(
                          color: myBlue60,
                          value: downloadProgress.progress,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              error.toString().contains('HTTP request failed')
                                  ? 'HTTP request failed, statusCode: 0'
                                  : 'Failed to load image',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});  // This will trigger a rebuild and retry loading
                              },
                              child: Text(
                                'Retry',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      memCacheWidth: maxWidth.round(),
                      memCacheHeight: maxHeight.round(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
} 