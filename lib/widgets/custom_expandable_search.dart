import 'dart:math';

import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';

class CustomExpandableSearch extends StatefulWidget {
  final Function(String) onChanged;
  final String hintText;

  const CustomExpandableSearch({
    super.key,
    required this.onChanged,
    required this.hintText,
  });

  @override
  State<CustomExpandableSearch> createState() => _CustomExpandableSearchState();
}

class _CustomExpandableSearchState extends State<CustomExpandableSearch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _textController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
        _textController.clear();
        widget.onChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = windowWidth < 600;
    return isSmallScreen ? const SizedBox.shrink() : Container(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: min(240, windowWidth * 0.25),
            margin: const EdgeInsets.only(right: 16),
            child: CustomFocusTextField(
              label: '',
              hintText: widget.hintText,
              controller: _textController,
              onChanged: widget.onChanged,
              prefixIcon: Icons.search,
              height: 48,
              shouldShowBorder: true,
            ),
          ),
          /*
          SizedBox(
            height: 40,
            width: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _isExpanded ? Icons.close : Icons.search,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _toggleSearch,
            ),
          ),
          */
        ],
      ),
    );
  }
} 