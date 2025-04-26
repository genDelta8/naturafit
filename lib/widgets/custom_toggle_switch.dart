import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomToggleSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const CustomToggleSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
    this.width = 50.0,
    this.height = 28.0,
  }) : super(key: key);

  @override
  State<CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<CustomToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomToggleSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: _animation.value > 0.5 ? myBlue30 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _animation.value > 0.5 ? myBlue60 : theme.brightness == Brightness.light ? myGrey30 : myGrey70,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _animation.value * (widget.width - widget.height + 0),
                    child: Container(
                      width: widget.height - 4,
                      height: widget.height - 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 