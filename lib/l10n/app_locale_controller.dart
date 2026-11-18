import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController {
  AppLocaleController._();

  static final ValueNotifier<Locale> current = ValueNotifier<Locale>(
    const Locale('fr'),
  );
  static const _languagePreferenceKey = 'app_language';

  static Future<void> loadSavedLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_languagePreferenceKey);
    current.value = Locale(savedLanguage == 'en' ? 'en' : 'fr');
  }

  static Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'fr' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _languagePreferenceKey,
      languageCode,
    );
    if (!saved) {
      throw StateError('Could not persist the selected language.');
    }
    current.value = Locale(languageCode);
  }
}
