import 'package:naturafit/utilities/platform_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomSelectableList extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;
  final Function(String) onItemSelected;
  final Function(String) onItemDeselected;

  const CustomSelectableList({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onItemSelected,
    required this.onItemDeselected,
  });

  @override
  State<CustomSelectableList> createState() => _CustomSelectableListState();
}

class _CustomSelectableListState extends State<CustomSelectableList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      height: myIsWebOrDektop ? 360 : 270,
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(theme.brightness == Brightness.light ? myGrey60 : myGrey40),
          trackColor: WidgetStateProperty.all(theme.brightness == Brightness.light ? myGrey20 : myGrey80),
        ),
        child: Scrollbar(
          controller: _scrollController,
          trackVisibility: true,
          thumbVisibility: true,
          thickness: 8,
          radius: const Radius.circular(2),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(right: 14),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected = widget.selectedItems.contains(item);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? myBlue30 : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 3,
                      ),
                      onTap: () {
                        if (isSelected) {
                          widget.onItemDeselected(item);
                        } else {
                          widget.onItemSelected(item);
                        }
                      },
                      title: Text(
                        item,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                        ),
                      ),
                      trailing: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.transparent : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: isSelected 
                          ? const Icon(
                              Icons.check,
                              size: 15,
                              color: myBlue60,
                            )
                          : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 