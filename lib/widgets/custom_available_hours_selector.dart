import 'package:naturafit/widgets/custom_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class CustomAvailableHoursSelector extends StatefulWidget {
  final Function(Map<String, List<TimeRange>>) onChanged;
  final Map<String, List<TimeRange>>? initialValue;
  final bool use24HourFormat;

  const CustomAvailableHoursSelector({
    super.key,
    required this.onChanged,
    this.initialValue,
    required this.use24HourFormat,
  });

  @override
  State<CustomAvailableHoursSelector> createState() => _CustomAvailableHoursSelectorState();
}

class _CustomAvailableHoursSelectorState extends State<CustomAvailableHoursSelector> {
  final Map<String, List<TimeRange>> _availability = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _availability.addAll(widget.initialValue!);
    }
  }

  void _toggleDayAvailability(String day) {
    setState(() {
      if (_availability[day]!.isEmpty) {
        // If currently unavailable, add default time range (9 AM - 5 PM)
        _availability[day] = [
          TimeRange(
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 17, minute: 0),
          ),
        ];
      } else {
        // If currently available, clear the time ranges
        _availability[day] = [];
      }
      widget.onChanged(Map<String, List<TimeRange>>.from(_availability));
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    if (widget.use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      return time.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availability.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final day = _availability.keys.elementAt(index);
            final timeRanges = _availability[day]!;
            final isAvailable = timeRanges.isNotEmpty;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isAvailable ? myBlue30 : Colors.transparent,
              ),
              child: Card(
                color: isAvailable ? myBlue60 : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                elevation: isAvailable ? 0 : 1,
                margin: const EdgeInsets.all(4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  title: Text(
                    day,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: isAvailable ? Colors.white : theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAvailable) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picked = await CustomTimePicker.show(
                                  context: context,
                                  initialTime: timeRanges.first.start,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _availability[day] = [
                                      timeRanges.first.copyWith(start: picked),
                                    ];
                                    widget.onChanged(Map<String, List<TimeRange>>.from(_availability));
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  _formatTimeOfDay(timeRanges.first.start),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: myGrey90,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '-',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final picked = await CustomTimePicker.show(
                                  context: context,
                                  initialTime: timeRanges.first.end,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _availability[day] = [
                                      timeRanges.first.copyWith(end: picked),
                                    ];
                                    widget.onChanged(Map<String, List<TimeRange>>.from(_availability));
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  _formatTimeOfDay(timeRanges.first.end),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: myGrey90,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Unavailable',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _toggleDayAvailability(day),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.white : theme.brightness == Brightness.light ? Colors.white : myGrey80,
                            border: Border.all(
                              color: isAvailable ? Colors.transparent : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: isAvailable
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: myBlue60,
                              )
                            : null,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _toggleDayAvailability(day),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({
    required this.start,
    required this.end,
  });

  TimeRange copyWith({
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return TimeRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
} 