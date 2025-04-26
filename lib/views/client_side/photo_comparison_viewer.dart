import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/views/client_side/photo_comparison_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhotoComparisonViewer extends StatefulWidget {
  final SelectedPhoto photo1;
  final SelectedPhoto photo2;

  const PhotoComparisonViewer({
    super.key,
    required this.photo1,
    required this.photo2,
  });

  @override
  State<PhotoComparisonViewer> createState() => _PhotoComparisonViewerState();
}

class _PhotoComparisonViewerState extends State<PhotoComparisonViewer> {
  double _sliderPosition = 0.5; // Start at half width

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Row(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(widget.photo1.date),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.vs,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMM d, yyyy').format(widget.photo2.date),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Bottom (full width) image
          CachedNetworkImage(
            imageUrl: widget.photo2.photoUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: myGrey20,
              child: const Center(
                child: CircularProgressIndicator(color: myGrey30),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: myGrey20,
              child: const Icon(Icons.person_outline, color: myGrey60),
            ),
          ),

          // Top (sliding) image
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: _sliderPosition,
              child: CachedNetworkImage(
            imageUrl: widget.photo1.photoUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: myGrey20,
              child: const Center(
                child: CircularProgressIndicator(color: myGrey30),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: myGrey20,
              child: const Icon(Icons.person_outline, color: myGrey60),
            ),
          ),
            ),
          ),
          // Slider
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final width = box.size.width;
                setState(() {
                  _sliderPosition = (_sliderPosition + details.delta.dx / width)
                      .clamp(0.0, 1.0);
                });
              },
              child: Stack(
                children: [
                  // Slider line
                  Positioned(
                    left: MediaQuery.of(context).size.width * _sliderPosition - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.white,
                    ),
                  ),
                  // Slider handle
                  Positioned(
                    left: MediaQuery.of(context).size.width * _sliderPosition - 15,
                    top: MediaQuery.of(context).size.height / 2 - 15,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.compare_arrows,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getComparisonTitle(AppLocalizations l10n, String viewType) {
    switch (viewType) {
      case 'front':
        return l10n.front_view_comparison;
      case 'back':
        return l10n.back_view_comparison;
      case 'side':
        return l10n.side_view_comparison;
      default:
        return l10n.photo_comparison;
    }
  }
} 