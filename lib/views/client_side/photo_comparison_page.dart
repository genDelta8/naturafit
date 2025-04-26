import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/views/client_side/progress_photo_viewer.dart';
import 'package:naturafit/views/client_side/photo_comparison_viewer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhotoComparisonPage extends StatefulWidget {
  final List<Map<String, dynamic>> progressLogs;

  const PhotoComparisonPage({
    super.key,
    required this.progressLogs,
  });

  @override
  State<PhotoComparisonPage> createState() => _PhotoComparisonPageState();
}

class _PhotoComparisonPageState extends State<PhotoComparisonPage> {
  bool _selectionMode = false;
  final List<SelectedPhoto> _selectedPhotos = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final baseInitialColor = myGrey60;
    final fadeInitialColor = myGrey30;

    final baseSelectedColor = myTeal60;
    final fadeSelectedColor = myTeal30;

    final baseCompareColor = myBlue60;
    final fadeCompareColor = myBlue30;

    return Scaffold(
      backgroundColor: myGrey10,
      appBar: AppBar(
        title: Text(
          l10n.photo_comparison,
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: myGrey10,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            child: GestureDetector(
                onTap: () {
                  if (_selectionMode && _selectedPhotos.length == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoComparisonViewer(
                          photo1: _selectedPhotos[0],
                          photo2: _selectedPhotos[1],
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      _selectedPhotos.clear();
                    });
                  }
                },
                child: Container(
                  width: 120,
                  //height: 120,
                  decoration: BoxDecoration(
                    color: _selectionMode
                        ? (_selectedPhotos.length == 2
                            ? fadeCompareColor
                            : fadeSelectedColor)
                        : fadeInitialColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _selectionMode
                              ? (_selectedPhotos.length == 2
                                  ? baseCompareColor
                                  : baseSelectedColor)
                              : baseInitialColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectionMode
                              ? (_selectedPhotos.length == 2
                                  ? l10n.compare
                                  : l10n.select_photos)
                              : l10n.select_photos,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_selectedPhotos.length < 2)
                        Text(
                          _selectionMode
                              ? (_selectedPhotos.length == 2
                                  ? ''
                                  : l10n.selected_count(_selectedPhotos.length))
                              : l10n.to_compare,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            l10n.select_date,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_selectedPhotos.isEmpty)
            Center(
              child: Text(
                l10n.no_photos_selected,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.progressLogs.length,
            itemBuilder: (context, index) {
              final log = widget.progressLogs[index];
              final photos = log['progressPhotos'] as Map<String, dynamic>;
              final date = (log['date'] as Timestamp).toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (photos['frontPhoto'] != null) ...[
                            _buildPhotoThumbnail(
                              context,
                              photos['frontPhoto'],
                              'Front',
                              photos,
                              date,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (photos['backPhoto'] != null) ...[
                            _buildPhotoThumbnail(
                              context,
                              photos['backPhoto'],
                              'Back',
                              photos,
                              date,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (photos['leftSidePhoto'] != null) ...[
                            _buildPhotoThumbnail(
                              context,
                              photos['leftSidePhoto'],
                              'Left Side',
                              photos,
                              date,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (photos['rightSidePhoto'] != null) ...[
                            _buildPhotoThumbnail(
                              context,
                              photos['rightSidePhoto'],
                              'Right Side',
                              photos,
                              date,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(
    BuildContext context,
    String photoUrl,
    String label,
    Map<String, dynamic> allPhotos,
    DateTime date,
  ) {
    final isSelected = _selectedPhotos
        .any((photo) => photo.photoUrl == photoUrl && photo.date == date);

    String getLocalizedLabel(String label) {
      switch (label.toLowerCase()) {
        case 'front':
          return AppLocalizations.of(context)!.front;
        case 'back':
          return AppLocalizations.of(context)!.back;
        case 'left side':
          return AppLocalizations.of(context)!.left;
        case 'right side':
          return AppLocalizations.of(context)!.right;
        default:
          return label;
      }
    }

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          setState(() {
            if (isSelected) {
              _selectedPhotos.removeWhere(
                  (photo) => photo.photoUrl == photoUrl && photo.date == date);
            } else if (_selectedPhotos.length < 2) {
              _selectedPhotos.add(SelectedPhoto(
                photoUrl: photoUrl,
                label: label,
                date: date,
              ));
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgressPhotoViewer(
                photos: allPhotos,
                date: date,
                initialView: label.toLowerCase(),
              ),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  ),
                  border:
                      isSelected ? Border.all(color: myBlue60, width: 3) : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                getLocalizedLabel(label),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: myGrey60,
                ),
              ),
            ],
          ),
          if (isSelected)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: myBlue60,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_selectedPhotos.indexOf(_selectedPhotos.firstWhere((photo) => photo.photoUrl == photoUrl && photo.date == date)) + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SelectedPhoto {
  final String photoUrl;
  final String label;
  final DateTime date;

  SelectedPhoto({
    required this.photoUrl,
    required this.label,
    required this.date,
  });
}
