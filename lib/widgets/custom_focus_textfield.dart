import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomFocusTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final VoidCallback? onSuffixTap;
  final bool readOnly;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool isRequired;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool shouldShowBorder;
  final bool obscureText;
  final bool? isPassword;
  final bool shouldDisable;

  const CustomFocusTextField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSuffixTap,
    this.readOnly = false,
    this.width,
    this.height,
    this.maxLines = 1,
    this.isRequired = false,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.shouldShowBorder = false,
    this.obscureText = false,
    this.isPassword = false,
    this.shouldDisable = false,
  }) : super(key: key);

  @override
  State<CustomFocusTextField> createState() => _CustomFocusTextFieldState();
}

class _CustomFocusTextFieldState extends State<CustomFocusTextField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  fontSize: 16,
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        if (widget.label.isNotEmpty) const SizedBox(height: 0),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {});
          },
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 40),
                curve: Curves.fastOutSlowIn,
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFocus ? widget.isPassword == true ? myRed20 : myBlue20 : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: true //widget.shouldShowBorder
                        ? Border.all(
                            color: hasFocus 
                                ? widget.isPassword == true ? myRed50 : myBlue60 
                                : theme.brightness == Brightness.light 
                                    ? myGrey20 
                                    : myGrey80,
                            width: 1,
                          )
                        : null,
                  ),
                  child: TextFormField(
                    enabled: !widget.shouldDisable,
                    obscureText: widget.obscureText,
                    readOnly: widget.readOnly,
                    maxLines: widget.maxLines,
                    keyboardType: widget.keyboardType,
                    maxLength: widget.maxLength,
                    cursorWidth: 1,
                    cursorColor: theme.brightness == Brightness.light 
                        ? Colors.black 
                        : Colors.white,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.shouldDisable
                          ? theme.brightness == Brightness.light 
                              ? myGrey60 
                              : myGrey40
                          : null,
                    ),
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.light 
                            ? myGrey40 
                            : myGrey60,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: widget.prefixIcon != null
                          ? Icon(
                              widget.prefixIcon,
                              color: theme.brightness == Brightness.light 
                                  ? myGrey60 
                                  : myGrey40,
                              size: 20,
                            )
                          : null,
                      suffixIcon: widget.suffixIcon != null
                          ? GestureDetector(
                              onTap: widget.onSuffixTap,
                              child: widget.suffixIcon,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: widget.onChanged,
                    inputFormatters: widget.inputFormatters,
                    validator: widget.validator,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 