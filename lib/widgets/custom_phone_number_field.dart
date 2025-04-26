import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomPhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Function(String)? onChanged;
  final String? initialCountryCode;
  final String? initialCountryFlag;
  final String? passedHintText;
  final bool shouldDisable;
  const CustomPhoneNumberField({
    super.key,
    required this.controller,
    this.label = 'Phone Number',
    this.onChanged,
    this.initialCountryCode = '+1',
    this.initialCountryFlag = 'US',
    this.passedHintText,
    this.shouldDisable = false,
  });

  @override
  State<CustomPhoneNumberField> createState() => _CustomPhoneNumberFieldState();
}

class _CustomPhoneNumberFieldState extends State<CustomPhoneNumberField> {
  late String _selectedCountryCode;
  late String _selectedCountryFlag;
  final TextEditingController _phoneNumberController = TextEditingController();

  final List<Map<String, String>> _countryCodes = [
    {'name': 'United States', 'code': '+1', 'flag': 'US'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': 'GB'},
    {'name': 'Australia', 'code': '+61', 'flag': 'AU'},
    {'name': 'Canada', 'code': '+1', 'flag': 'CA'},
    {'name': 'New Zealand', 'code': '+64', 'flag': 'NZ'},
    {'name': 'Ireland', 'code': '+353', 'flag': 'IE'},
    {'name': 'Spain', 'code': '+34', 'flag': 'ES'},
    {'name': 'Italy', 'code': '+39', 'flag': 'IT'},
    {'name': 'France', 'code': '+33', 'flag': 'FR'},
    {'name': 'Germany', 'code': '+49', 'flag': 'DE'},
    {'name': 'Turkey', 'code': '+90', 'flag': 'TR'},
    {'name': 'India', 'code': '+91', 'flag': 'IN'},
    {'name': 'China', 'code': '+86', 'flag': 'CN'},
    {'name': 'Japan', 'code': '+81', 'flag': 'JP'},
    {'name': 'South Korea', 'code': '+82', 'flag': 'KR'},
    {'name': 'Brazil', 'code': '+55', 'flag': 'BR'},
    {'name': 'Mexico', 'code': '+52', 'flag': 'MX'},
    {'name': 'Singapore', 'code': '+65', 'flag': 'SG'},
    {'name': 'Netherlands', 'code': '+31', 'flag': 'NL'},
    {'name': 'Sweden', 'code': '+46', 'flag': 'SE'},
    {'name': 'Norway', 'code': '+47', 'flag': 'NO'},
    {'name': 'Denmark', 'code': '+45', 'flag': 'DK'},
    {'name': 'Switzerland', 'code': '+41', 'flag': 'CH'},
    {'name': 'Belgium', 'code': '+32', 'flag': 'BE'},
    {'name': 'United Arab Emirates', 'code': '+971', 'flag': 'AE'},
    {'name': 'Saudi Arabia', 'code': '+966', 'flag': 'SA'},
    {'name': 'Qatar', 'code': '+974', 'flag': 'QA'},
    {'name': 'Kuwait', 'code': '+965', 'flag': 'KW'},
    {'name': 'Bahrain', 'code': '+973', 'flag': 'BH'},
    {'name': 'Oman', 'code': '+968', 'flag': 'OM'},
    {'name': 'South Africa', 'code': '+27', 'flag': 'ZA'},
    {'name': 'Egypt', 'code': '+20', 'flag': 'EG'},
    {'name': 'Nigeria', 'code': '+234', 'flag': 'NG'},
    {'name': 'Kenya', 'code': '+254', 'flag': 'KE'},
    {'name': 'Malaysia', 'code': '+60', 'flag': 'MY'},
    {'name': 'Indonesia', 'code': '+62', 'flag': 'ID'},
    {'name': 'Philippines', 'code': '+63', 'flag': 'PH'},
    {'name': 'Thailand', 'code': '+66', 'flag': 'TH'},
    {'name': 'Vietnam', 'code': '+84', 'flag': 'VN'},
    {'name': 'Pakistan', 'code': '+92', 'flag': 'PK'},
    {'name': 'Bangladesh', 'code': '+880', 'flag': 'BD'},
    {'name': 'Russia', 'code': '+7', 'flag': 'RU'},
    {'name': 'Ukraine', 'code': '+380', 'flag': 'UA'},
    {'name': 'Poland', 'code': '+48', 'flag': 'PL'},
    {'name': 'Austria', 'code': '+43', 'flag': 'AT'},
    {'name': 'Greece', 'code': '+30', 'flag': 'GR'},
    {'name': 'Portugal', 'code': '+351', 'flag': 'PT'},
    {'name': 'Finland', 'code': '+358', 'flag': 'FI'},
    {'name': 'Argentina', 'code': '+54', 'flag': 'AR'},
    {'name': 'Chile', 'code': '+56', 'flag': 'CL'},
    {'name': 'Colombia', 'code': '+57', 'flag': 'CO'},
    {'name': 'Peru', 'code': '+51', 'flag': 'PE'},
    {'name': 'Israel', 'code': '+972', 'flag': 'IL'},
    {'name': 'Hong Kong', 'code': '+852', 'flag': 'HK'},
    {'name': 'Taiwan', 'code': '+886', 'flag': 'TW'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode!;
    _selectedCountryFlag = widget.initialCountryFlag!;
    
    // Parse initial value that includes flag code
    if (widget.controller.text.isNotEmpty) {
      final parts = widget.controller.text.split('|');
      if (parts.length == 3) {
        _selectedCountryFlag = parts[0];
        _selectedCountryCode = parts[1];
        _phoneNumberController.text = parts[2];
      }
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          border: Border.all(color: theme.brightness == Brightness.light ? myGrey40 : myGrey80),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.select_country_code,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  return ListTile(
                    leading: CountryFlag.fromCountryCode(
                      country['flag']!,
                      height: 24,
                      width: 32,
                    ),
                    title: Text(country['name']!),
                    trailing: Text(
                      country['code']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                      });
                      _updateMainController();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMainController() {
    // Store as "flagCode|countryCode|phoneNumber"
    widget.controller.text = '$_selectedCountryFlag|$_selectedCountryCode|${_phoneNumberController.text}';
    if (widget.onChanged != null) {
      widget.onChanged!(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.brightness == Brightness.light ? myGrey90 : Colors.white,
                  fontSize: 16,
                ),
        ),
        const SizedBox(height: 0),
        Row(
          children: [
            GestureDetector(
              onTap: widget.shouldDisable ? null : _showCountryPicker,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? Colors.white : myGrey90,
                  border: Border.all(color: theme.brightness == Brightness.light ? myGrey20 : myGrey80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CountryFlag.fromCountryCode(
                      _selectedCountryFlag,
                      height: 24,
                      width: 32,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountryCode,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: myGrey60),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomFocusTextField(
                label: '',
                hintText: widget.passedHintText ?? l10n.enter_phone_number,
                controller: _phoneNumberController,
                prefixIcon: Icons.phone_outlined,
                onChanged: (value) {
                  _updateMainController();
                },
                shouldDisable: widget.shouldDisable,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get selectedCountryCode => _selectedCountryCode;
} 