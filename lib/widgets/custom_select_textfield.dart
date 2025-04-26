import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomSelectTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final List<String> options;
  final Function(String)? onChanged;
  final bool isRequired;
  final double? width;
  final double? height;

  const CustomSelectTextField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.options,
    this.prefixIcon,
    this.onChanged,
    this.isRequired = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<CustomSelectTextField> createState() => _CustomSelectTextFieldState();
}

class _CustomSelectTextFieldState extends State<CustomSelectTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _createOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _overlayEntry = _customOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _customOverlayEntry() {
    final theme = Theme.of(context);
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height - 24.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            color: theme.cardColor,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      widget.controller.text = widget.options[index];
                      if (widget.onChanged != null) {
                        widget.onChanged!(widget.options[index]);
                      }
                      _removeOverlay();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        widget.options[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.brightness == Brightness.light 
                              ? myGrey90 
                              : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
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
        CompositedTransformTarget(
          link: _layerLink,
          child: Focus(
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
                      color: hasFocus ? myBlue20 : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasFocus 
                            ? Colors.transparent 
                            : theme.brightness == Brightness.light 
                                ? myGrey20 
                                : myGrey80,
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      cursorWidth: 1,
                      cursorColor: theme.brightness == Brightness.light 
                          ? Colors.black 
                          : Colors.white,
                      focusNode: _focusNode,
                      controller: widget.controller,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.brightness == Brightness.light 
                                ? myGrey60 
                                : myGrey40,
                          ),
                          onPressed: () {
                            if (_overlayEntry == null) {
                              _createOverlay();
                            } else {
                              _removeOverlay();
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: myBlue60,
                            width: 1,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        if (widget.onChanged != null) {
                          widget.onChanged!(value);
                        }
                        if (_overlayEntry != null) {
                          _overlayEntry?.markNeedsBuild();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
} 