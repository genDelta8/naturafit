import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomUserProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double borderRadius;
  final bool isGroup;
  final bool isAvailable;
  final Color backgroundColor;

  const CustomUserProfileImage({
    Key? key,
    this.imageUrl,
    required this.name,
    this.size = 48,
    this.borderRadius = 8,
    this.isGroup = false,
    this.isAvailable = false,
    this.backgroundColor = myGrey30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return CircleAvatar(
        backgroundColor: myBlue20,
        radius: size / 2,
        child: const Icon(
          Icons.groups,
          color: myBlue60,
        ),
      );
    }

    if (isAvailable) {
      return CircleAvatar(
        backgroundColor: myBlue20,
        radius: size / 2,
        child: const Icon(
          Icons.person,
          color: myBlue60,
        ),
      );
    }

    if (imageUrl != null && imageUrl != '' && imageUrl != 'null') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: imageUrl.toString().startsWith('assets/') 
              ? myAvatarBackground 
              : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: imageUrl.toString().startsWith('assets/')
              ? Image.asset(
                  imageUrl!,
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: myGrey20,
                    child: const Center(
                      child: CircularProgressIndicator(color: myGrey30),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: myGrey20,
                    child: const Icon(
                      Icons.person_outline,
                      color: myGrey60,
                    ),
                  ),
                ),

        ),
      );
    }

    // Fallback to initials
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 