import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomSelectExerciseMealTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final List<Map<String, dynamic>> options;
  final Function(String name, String? id)? onChanged;
  final bool isRequired;
  final double? width;
  final double? height;
  final bool isExercise;

  const CustomSelectExerciseMealTextField({
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
    this.isExercise = true,
  });

  @override
  State<CustomSelectExerciseMealTextField> createState() => _CustomSelectExerciseMealTextFieldState();
}

class _CustomSelectExerciseMealTextFieldState extends State<CustomSelectExerciseMealTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredOptions = [];

  @override
  void initState() {
    super.initState();
    filteredOptions = widget.options;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    if (query.isEmpty) {
      filteredOptions = widget.options;
    } else {
      filteredOptions = widget.options
          .where((option) => option['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    _overlayEntry?.markNeedsBuild();
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
    final l10n = AppLocalizations.of(context)!;

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
                maxHeight: 300,
                minWidth: size.width,
              ),
              child: widget.options.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isExercise 
                                ? Icons.fitness_center 
                                : Icons.restaurant,
                            color: myGrey60,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isExercise
                                ? l10n.exercises_you_use_in_your_workout_plans_will_appear_here_for_quick_access
                                : l10n.meals_you_create_in_your_meal_plans_will_appear_here_for_quick_access,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: myGrey60,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
                          child: CustomFocusTextField(
                            label: '',
                            hintText: 'Search ${widget.isExercise ? "exercises" : "meals"}...',
                            controller: _searchController,
                            prefixIcon: Icons.search,
                            onChanged: _filterOptions,
                          ),
                          
                          
                        ),
                        //const Divider(height: 1, color: myGrey30),
                        Flexible(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: filteredOptions.length,
                            itemBuilder: (context, index) {
                              final item = filteredOptions[index];
                              return InkWell(
                                onTap: () {
                                  widget.controller.text = item['name'];
                                  if (widget.onChanged != null) {
                                    widget.onChanged!(
                                      item['name'],
                                      widget.isExercise
                                          ? item['exerciseId']
                                          : item['mealId'],
                                    );
                                  }
                                  _searchController.clear();
                                  _removeOverlay();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    item['name'],
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
                      ],
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
                ),
              ),
              if (widget.isRequired)
                Text(
                  ' *',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: myRed50,
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
                          onPressed: _createOverlay,
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
                          widget.onChanged!(value, null);
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