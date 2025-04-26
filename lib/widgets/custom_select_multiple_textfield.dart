import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomSelectMultipleTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final List<String> options;
  final Function(List<String>)? onChanged;
  final bool isRequired;
  final int maxLines;
  final List<String> initialSelected;
  final IconData? prefixIcon;

  const CustomSelectMultipleTextField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.options,
    this.onChanged,
    this.isRequired = false,
    this.maxLines = 3,
    this.initialSelected = const [],
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<CustomSelectMultipleTextField> createState() => _CustomSelectMultipleTextFieldState();
}

class _CustomSelectMultipleTextFieldState extends State<CustomSelectMultipleTextField> {
  late List<String> _selectedOptions;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.from(widget.initialSelected);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) => setState(() {}),
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasFocus ? myBlue60 : myGrey20,
                    width: hasFocus ? 1 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    TextFormField(
                      focusNode: _focusNode,
                      controller: widget.controller,
                      maxLines: widget.maxLines,
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        prefixIcon: widget.prefixIcon != null 
                          ? Icon(
                              widget.prefixIcon, 
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                              size: 20,
                            )
                          : null,
                        contentPadding: EdgeInsets.fromLTRB(
                          widget.prefixIcon != null ? 0 : 16,
                          16,
                          48,
                          16
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                        ),
                        onPressed: () => _showSelectionSheet(theme),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSelectionSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.transparent : myGrey80),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.controller.text = _selectedOptions.join(', ');
                        if (widget.onChanged != null) {
                          widget.onChanged!(_selectedOptions);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          color: myBlue60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = _selectedOptions.contains(option);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (theme.brightness == Brightness.light ? myBlue10 : myGrey80)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? myBlue60 : myGrey20,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedOptions.remove(option);
                            } else {
                              _selectedOptions.add(option);
                            }
                          });
                        },
                        title: Text(
                          option,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected 
                                ? myBlue60 
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? myBlue60 : myGrey40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 