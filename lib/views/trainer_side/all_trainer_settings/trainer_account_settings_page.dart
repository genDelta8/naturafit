import 'package:naturafit/services/firebase_service.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_date_spinner.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_gender_picker.dart';
import 'package:naturafit/widgets/custom_profile_photo_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:country_flags/country_flags.dart';
import 'package:naturafit/widgets/custom_phone_number_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/utilities/platform_check.dart';

class TrainerAccountSettingsPage extends StatefulWidget {
  final String initialFullName;
  final String initialEmail;
  final String initialPhone;
  final String initialLocation;
  final String? initialProfileImageURL;

  const TrainerAccountSettingsPage({
    super.key,
    required this.initialFullName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialLocation,
    this.initialProfileImageURL,
  });

  @override
  State<TrainerAccountSettingsPage> createState() => _TrainerAccountSettingsPageState();
}

class _TrainerAccountSettingsPageState extends State<TrainerAccountSettingsPage> {
  final _basicProfileForm = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  File? _selectedImageFile;
  Uint8List? _webImageBytes;
  
  // Date related variables
  int _selectedDay = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year - 25; // Default to 25 years ago

  // Add this variable to track changes
  bool _hasUnsavedChanges = false;

  // Add this method to check for changes
  void _checkForChanges() {
    final fullNameChanged = _fullNameController.text != widget.initialFullName;
    final emailChanged = _emailController.text != widget.initialEmail;
    final phoneChanged = _phoneController.text != widget.initialPhone;
    final locationChanged = _locationController.text != widget.initialLocation;
    final imageChanged = _selectedImageFile != null || _webImageBytes != null;

    setState(() {
      _hasUnsavedChanges = fullNameChanged || emailChanged || phoneChanged || 
                          locationChanged || imageChanged;
    });
  }

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialFullName;
    _emailController.text = widget.initialEmail;
    
    // Handle phone number format
    // If phone is in new format (flag|code|number), pass it directly
    // Otherwise use default empty value
    _phoneController.text = widget.initialPhone.contains('|') 
        ? widget.initialPhone 
        : 'US|+1|'; // Default value if no phone number
        
    _locationController.text = widget.initialLocation;

    // Add listeners to track changes
    _fullNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _locationController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _locationController.removeListener(_checkForChanges);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToFirebase(BuildContext context) async {
    if (_selectedImageFile == null && _webImageBytes == null) return null;

    if (isWebOrDesktopCached && _webImageBytes != null) {
      // For web, use the bytes directly
      return await FirebaseService().uploadProfileImageBytes(_webImageBytes!);
    } else if (_selectedImageFile != null) {
      // For mobile or when we have a file
      return await FirebaseService().uploadProfileImage(_selectedImageFile!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final userData = userProvider.userData;
    final randomUsername = userData?['username'] ?? '';
    final userRole = userData?['role'] ?? '';
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.account_settings,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _hasUnsavedChanges
              ? () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: myBlue60),
                      ),
                    );

                    // Prepare the updated data
                    final updatedData = {
                      'fullName': _fullNameController.text != '' ? _fullNameController.text : randomUsername,
                      'email': _emailController.text,
                      'phone': _phoneController.text != '' ? _phoneController.text : '',
                      'location': _locationController.text,
                    };

                    String? imageUrl;
                    // Handle image upload for both web and mobile
                    if (_selectedImageFile != null || _webImageBytes != null) {
                      // Check if the selected image is an avatar (asset path)
                      if (_selectedImageFile?.path.startsWith('assets/') ?? false) {
                        // For avatars, just store the asset path directly
                        imageUrl = _selectedImageFile!.path;
                      } else {
                        // For real files or web images, upload to Firebase Storage
                        imageUrl = await _uploadImageToFirebase(context);
                      }
                      if (imageUrl != null) {
                        updatedData[fbProfileImageURL] = imageUrl;
                      }
                    }

                    // Check if fullName or profileImage changed
                    final bool fullNameChanged = _fullNameController.text != widget.initialFullName;
                    final bool profileImageChanged = imageUrl != null;

                    if (fullNameChanged || profileImageChanged) {
                      final userId = userData?['userId'];
                      if (userId != null) {
                        // Update connections for both fullName and/or profileImageURL changes
                        await FirebaseService().updateConnectionsData(
                          userId: userId,
                          role: userRole,
                          fullName: fullNameChanged ? _fullNameController.text : null,
                          username: randomUsername,
                          profileImageURL: profileImageChanged ? imageUrl : null,
                        );
                      }
                    }

                    // Update in Firebase
                    if (context.mounted) {
                      await FirebaseService().updateUser(updatedData, context);
                    }

                    // Update UserProvider
                    if (context.mounted) {
                      final userProvider = context.read<UserProvider>();
                      final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
                      currentData.addAll(updatedData);
                      userProvider.setUserData(currentData);

                      Navigator.pop(context); // Close loading dialog
                      Navigator.pop(context); // Return to settings page
                    }
                  } catch (e) {
                    if (context.mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.update_failed),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.ok),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              : null,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _hasUnsavedChanges ? myBlue30 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasUnsavedChanges ? myBlue60 : myGrey30,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.plusJakartaSans(
                    color: _hasUnsavedChanges ? Colors.white : myGrey60,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildBasicProfileStep(),
    );
  }

  Widget _buildBasicProfileStep() {
    final userData = context.read<UserProvider>().userData;
    final randomUsername = userData?['username'] ?? AppLocalizations.of(context)!.enter_full_name;
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _basicProfileForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfilePhotoPicker(),
                const SizedBox(height: 8),
                CustomFocusTextField(
                  label: l10n.full_name,
                  hintText: randomUsername,
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline,
                  onChanged: (value) {
                    _checkForChanges();
                  },
                ),
                const SizedBox(height: 16),
                CustomFocusTextField(
                  label: l10n.email_address,
                  hintText: l10n.enter_email,
                  controller: _emailController,
                  prefixIcon: Icons.mail_outline,
                  onChanged: (value) {
                    _checkForChanges();
                  },
                ),
                const SizedBox(height: 16),
                CustomPhoneNumberField(
                  controller: _phoneController,
                  onChanged: (value) {
                    _checkForChanges();
                  },
                  initialCountryFlag: widget.initialPhone.contains('|') 
                      ? widget.initialPhone.split('|')[0] 
                      : 'US',
                  initialCountryCode: widget.initialPhone.contains('|') 
                      ? widget.initialPhone.split('|')[1] 
                      : '+1',
                ),
                const SizedBox(height: 16),
                CustomFocusTextField(
                  label: l10n.location_label,
                  hintText: l10n.location_hint,
                  controller: _locationController,
                  prefixIcon: Icons.location_on_outlined,
                  onChanged: (value) {
                    _checkForChanges();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoPicker() {
    return CustomProfilePhotoPicker(
      selectedImageFile: _selectedImageFile,
      webImage: _webImageBytes,
      initialImageUrl: widget.initialProfileImageURL,
      onImageSelected: (File file, [Uint8List? webImageBytes]) {
        setState(() {
          if (file.path.isEmpty) {
            _selectedImageFile = null;
            _webImageBytes = null;
          } else {
            _selectedImageFile = file;
            _webImageBytes = webImageBytes;
          }
        });
        _checkForChanges();
      },
    );
  }

  String getFormattedPhoneNumber(String storedValue) {
    final parts = storedValue.split('|');
    if (parts.length == 3) {
      return '${parts[1]}${parts[2]}'; // countryCode + phoneNumber
    }
    return storedValue;
  }
} 