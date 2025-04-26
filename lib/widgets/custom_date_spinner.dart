import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomDateSpinner extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final String? title;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDateSpinner({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
    this.title,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  State<CustomDateSpinner> createState() => _CustomDateSpinnerState();
}

class _CustomDateSpinnerState extends State<CustomDateSpinner> {
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isSpinnerMode = true;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    _selectedDay = date.day;
    _selectedMonth = date.month;
    _selectedYear = date.year;
  }

  void _updateDate() {
    widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  void _toggleDatePickerMode() {
    setState(() {
      _isSpinnerMode = !_isSpinnerMode;
    });
  }

  void _handleCalendarDateSelected(DateTime date) {
    setState(() {
      _selectedDay = date.day;
      _selectedMonth = date.month;
      _selectedYear = date.year;
      _updateDate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    
    return Card(
      elevation: 1,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isWideScreen ? 18 : 16,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpinnerMode ? Icons.calendar_month : Icons.view_day,
                      color: theme.iconTheme.color,
                    ),
                    onPressed: _toggleDatePickerMode,
                    tooltip: _isSpinnerMode ? 'Switch to Calendar' : 'Switch to Spinner',
                  ),
                ],
              ),
            if (_isSpinnerMode)
              Stack(
                children: [
                  Positioned.fill(
                    top: 40,
                    bottom: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light 
                            ? Colors.grey[100]
                            : myGrey90,
                        border: Border(
                          top: BorderSide(color: theme.brightness == Brightness.light 
                              ? Colors.grey[300]!
                              : myGrey80),
                          bottom: BorderSide(color: theme.brightness == Brightness.light 
                              ? Colors.grey[300]!
                              : myGrey80),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          NumberPicker(
                            value: _selectedMonth,
                            minValue: 1,
                            maxValue: 12,
                            itemHeight: isWideScreen ? 48 : 40,
                            itemWidth: isWideScreen ? 120 : 100,
                            infiniteLoop: true,
                            textMapper: (numberText) {
                              final months = [
                                'January', 'February', 'March', 'April',
                                'May', 'June', 'July', 'August',
                                'September', 'October', 'November', 'December'
                              ];
                              return months[int.parse(numberText) - 1];
                            },
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: theme.brightness == Brightness.light 
                                  ? Colors.grey[300]
                                  : myGrey70,
                            ),
                            selectedTextStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value;
                                _updateDate();
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          NumberPicker(
                            value: _selectedDay,
                            minValue: 1,
                            maxValue: 31,
                            itemHeight: isWideScreen ? 48 : 40,
                            itemWidth: isWideScreen ? 60 : 60,
                            infiniteLoop: true,
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: theme.brightness == Brightness.light 
                                  ? Colors.grey[300]
                                  : myGrey70,
                            ),
                            selectedTextStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedDay = value;
                                _updateDate();
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          NumberPicker(
                            value: _selectedYear,
                            minValue: widget.firstDate?.year ?? 1940,
                            maxValue: widget.lastDate?.year ?? DateTime.now().year,
                            itemHeight: isWideScreen ? 48 : 40,
                            itemWidth: isWideScreen ? 80 : 80,
                            infiniteLoop: false,
                            textStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: theme.brightness == Brightness.light 
                                  ? Colors.grey[300]
                                  : myGrey70,
                            ),
                            selectedTextStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                                _updateDate();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
            else
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: myBlue60,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: DateTime(_selectedYear, _selectedMonth, _selectedDay),
                  firstDate: widget.firstDate ?? DateTime(1940),
                  lastDate: widget.lastDate ?? DateTime.now(),
                  onDateChanged: _handleCalendarDateSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 