import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String hintText;
  final bool autofocus;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
    this.autofocus = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: _hasFocus ? myBlue20 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? myGrey70 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasFocus ? myBlue60 : Colors.transparent,
              width: 1,
            ),
          ),
          child: TextField(
            cursorWidth: 1,
            cursorColor: theme.brightness == Brightness.dark ? myGrey10 : Colors.black,
            controller: widget.controller,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: theme.brightness == Brightness.dark ? myGrey10 : myGrey90,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.brightness == Brightness.dark ? myGrey10 : myGrey60,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _hasFocus ? myGrey90 : myGrey60,
                size: 20,
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.brightness == Brightness.dark ? myGrey10 : myGrey60,
                        size: 20,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.brightness == Brightness.dark ? myGrey70 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 