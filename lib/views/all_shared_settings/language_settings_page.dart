import 'package:naturafit/main.dart';
import 'package:naturafit/services/deep_link_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/widgets/custom_checkbox_card.dart';
import 'package:country_flags/country_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:naturafit/services/locale_provider.dart';

class LanguageSettingsPage extends StatefulWidget {
  final String? initialLanguage;

  const LanguageSettingsPage({
    super.key,
    this.initialLanguage,
  });

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  static const String _languagePreferenceKey = 'app_language';
  String? _selectedLanguage;
  bool _isChanging = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'country': 'GB'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español', 'country': 'ES'},
    {'code': 'fr', 'name': 'French', 'native': 'Français', 'country': 'FR'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch', 'country': 'DE'},
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano', 'country': 'IT'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português', 'country': 'PT'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe', 'country': 'TR'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString(_languagePreferenceKey) ?? widget.initialLanguage;
    });
  }

  Future<void> _updateLanguage(Map<String, String> language) async {
    if (_isChanging) return;
    if (_selectedLanguage == language['code']) return;

    setState(() => _isChanging = true);

    try {
      // Update SharedPreferences and notify LocaleProvider
      await context.read<LocaleProvider>().setLocale(language['code']!);

      // Update local state and UserProvider
      if (context.mounted) {
        setState(() {
          _selectedLanguage = language['code'];
          _isChanging = false;
        });

        final userProvider = context.read<UserProvider>();
        final currentData = Map<String, dynamic>.from(userProvider.userData ?? {});
        currentData['language'] = language['code'];
        userProvider.setUserData(currentData);
      }

    } catch (e) {
      setState(() => _isChanging = false);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildSelectedLanguageCard() {
    final l10n = AppLocalizations.of(context)!;
    final selectedLang = _selectedLanguage != null 
      ? _languages.firstWhere((lang) => lang['code'] == _selectedLanguage)
      : null;

    return Container(
      decoration: BoxDecoration(
        color: selectedLang != null ? myRed30 : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedLang != null ? myRed50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedLang != null 
                    ? getLocalizedLanguage(l10n, selectedLang['name']!)
                    : l10n.no_language_selected,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: selectedLang != null ? Colors.white : myGrey90,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedLang != null ? selectedLang['native']! : 'No language selected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: selectedLang != null ? myGrey10 : myGrey60,
                  ),
                ),
              ],
            ),
            if (selectedLang != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  child: CountryFlag.fromCountryCode(
                    selectedLang['country']!,
                    height: 24,
                    width: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageList() {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _languages.length,
      itemBuilder: (context, index) {
        final language = _languages[index];
        final isSelected = _selectedLanguage == language['code'];
        
        return CustomCheckboxCard(
          title: getLocalizedLanguage(l10n, language['name']!),
          subtitle: language['native'],
          isSelected: isSelected,
          onTap: () => _updateLanguage(language),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          l10n.language_title,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selected_language,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectedLanguageCard(),
            const SizedBox(height: 32),
            Text(
              l10n.all_languages,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: theme.brightness == Brightness.light ? myGrey90 : myGrey10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLanguageList(),
          ],
        ),
      ),
    );
  }
}

String getLocalizedLanguage(AppLocalizations l10n, String langCode) {
  switch (langCode) {
    case 'English': return l10n.english;
    case 'Spanish': return l10n.spanish;
    case 'French': return l10n.french;
    case 'German': return l10n.german;
    case 'Italian': return l10n.italian;
    case 'Portuguese': return l10n.portuguese;
    case 'Turkish': return l10n.turkish;
    default: return langCode;
  }
}
