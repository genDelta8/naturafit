import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProgressPhotoViewer extends StatelessWidget {
  final Map<String, dynamic> photos;
  final DateTime date;
  final String initialView;

  const ProgressPhotoViewer({
    super.key,
    required this.photos,
    required this.date,
    required this.initialView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: myGrey20,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: myGrey20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          DateFormat('MMMM d, yyyy').format(date),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: myGrey20,
          ),
        ),
      ),
      body: PageView(
        controller: PageController(
          initialPage: initialView == 'front' ? 0 : 1,
        ),
        children: [
          if (photos['frontPhoto'] != null)
            _buildFullScreenPhoto(context, photos['frontPhoto'], l10n.front_view),
          if (photos['backPhoto'] != null)
            _buildFullScreenPhoto(context, photos['backPhoto'], l10n.back_view),
          if (photos['leftSidePhoto'] != null)
            _buildFullScreenPhoto(context, photos['leftSidePhoto'], l10n.left_side),
          if (photos['rightSidePhoto'] != null)
            _buildFullScreenPhoto(context, photos['rightSidePhoto'], l10n.right_side),
        ],
      ),
    );
  }

  Widget _buildFullScreenPhoto(BuildContext context, String photoUrl, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: photoUrl,
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: myGrey20,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
} 