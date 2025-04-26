import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class WebStatCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String description;
  final VoidCallback? onTap;

  const WebStatCard({
    super.key,
    required this.context,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    
    final isVerySmall = width < 600;
    final isSmall = width < 800;
    final isMedium = width < 1200;
    
    final cardHeight = isVerySmall ? 120.0 : isSmall ? 180.0 : 240.0;
    
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          padding: EdgeInsets.all(isVerySmall ? 16 : isSmall ? 24 : 32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(isVerySmall ? 16 : 24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: isVerySmall 
            ? _buildIconOnlyContent()
            : _buildFullContent(theme, isSmall, isMedium),
        ),
      ),
    );
  }

  Widget _buildIconOnlyContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullContent(ThemeData theme, bool isSmall, bool isMedium) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmall ? 20 : 24,
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: isSmall ? 8 : 12),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: isSmall ? 20 : isMedium ? 24 : 28,
                height: 1.1,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isSmall ? 4 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      fontSize: isSmall ? 16 : isMedium ? 18 : 20,
                      height: 1.2,
                    ),
                  ),
                  if (!isSmall) ...[
                    SizedBox(height: isSmall ? 2 : 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: myGrey60,
                        fontSize: isSmall ? 11 : 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 