import 'dart:math';

import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomProgressPhotoPicker extends StatelessWidget {
  final String title;
  final String description;
  final File? selectedImageFile;
  final Uint8List? webImage;
  final Function(File file, [Uint8List? webImageBytes]) onImageSelected;
  final IconData icon;

  const CustomProgressPhotoPicker({
    Key? key,
    required this.title,
    required this.description,
    required this.selectedImageFile,
    this.webImage,
    required this.onImageSelected,
    required this.icon,
  }) : super(key: key);

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        onImageSelected(File(image.path), bytes);
      } else {
        onImageSelected(File(image.path));
      }
    }
  }

  void _showImageSourceOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              if(!isWebOrDesktopCached)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(
                  l10n.take_photo,
                  style: GoogleFonts.plusJakartaSans(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                  l10n.choose_from_gallery,
                  style: GoogleFonts.plusJakartaSans(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearImage() {
    onImageSelected(File(''));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myWidth = min(MediaQuery.of(context).size.width * 0.4, 400).toDouble();
    final myHeight = myWidth * (4 / 3);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          GestureDetector(
            onTap: () => _showImageSourceOptions(context),
            child: Container(
              height: myHeight,
              width: myWidth,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.light ? myGrey20 : myGrey70,
                  width: 1,
                ),
              ),
              child: selectedImageFile != null || webImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb && webImage != null
                              ? Image.memory(
                                  webImage!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  selectedImageFile!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => onImageSelected(File('')),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => _showImageSourceOptions(context),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 48,
                          color: myGrey40,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: myGrey60,
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
} 