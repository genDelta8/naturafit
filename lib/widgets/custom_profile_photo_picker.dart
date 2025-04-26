import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/avatar_picker_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomProfilePhotoPicker extends StatelessWidget {
  final File? selectedImageFile;
  final Uint8List? webImage;
  final String? initialImageUrl;
  final Function(File file, [Uint8List? webImageBytes]) onImageSelected;

  const CustomProfilePhotoPicker({
    Key? key,
    this.selectedImageFile,
    this.webImage,
    required this.onImageSelected,
    this.initialImageUrl,
  }) : super(key: key);

  Future<void> _showImagePickerDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isWebOrDesktop = isWebOrDesktopCached;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? myGrey80 : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                title: Text(
                  l10n.photo_library,
                  style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    if (kIsWeb) {
                      final bytes = await image.readAsBytes();
                      onImageSelected(File(image.path), bytes);
                    } else {
                      onImageSelected(File(image.path));
                    }
                  }
                },
              ),
              if (!isWebOrDesktop) ...[
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined,
                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                  title: Text(
                    l10n.camera,
                    style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      onImageSelected(File(image.path));
                    }
                  },
                ),
              ],
              ListTile(
                leading: Icon(Icons.face_outlined,
                    color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                title: Text(
                  l10n.choose_avatar,
                  style: GoogleFonts.plusJakartaSans(
                      color: theme.brightness == Brightness.light ? myGrey90 : myGrey10),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AvatarPickerDialog(
                      onAvatarSelected: (String avatarPath) {
                        onImageSelected(File(avatarPath));
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImagePickerDialog(context),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: selectedImageFile != null || initialImageUrl != null || webImage != null
                    ? myAvatarBackground
                    : theme.brightness == Brightness.dark ? myGrey80 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark ? myGrey60 : myGrey20,
                  width: 2,
                ),
                image: _getImageProvider(),
              ),
              child: (selectedImageFile == null && initialImageUrl == null && webImage == null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.add_photo,
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (selectedImageFile != null || initialImageUrl != null || webImage != null) ...[
            const SizedBox(height: 0),
            TextButton(
              onPressed: () => onImageSelected(File('')),
              child: Text(
                l10n.remove_photo,
                style: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.dark ? myGrey60 : myGrey90,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  DecorationImage? _getImageProvider() {
    if (selectedImageFile != null) {
      if (selectedImageFile!.path.startsWith('assets/')) {
        return DecorationImage(
          image: AssetImage(selectedImageFile!.path),
          fit: BoxFit.cover,
        );
      } else if (kIsWeb && webImage != null) {
        return DecorationImage(
          image: MemoryImage(webImage!),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: FileImage(selectedImageFile!),
          fit: BoxFit.cover,
        );
      }
    } else if (initialImageUrl != null) {
      if (initialImageUrl!.startsWith('assets/')) {
        return DecorationImage(
          image: AssetImage(initialImageUrl!),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: NetworkImage(initialImageUrl!),
          fit: BoxFit.cover,
        );
      }
    }
    return null;
  }
}
