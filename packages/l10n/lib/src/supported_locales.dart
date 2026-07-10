import 'package:flutter/material.dart';

/// Supported locales for the application.
class SupportedLocales {
  SupportedLocales._();

  /// List of all supported locales.
  static const List<Locale> all = [
    Locale('en', 'US'), // English (US) — default
    Locale('en', 'GB'), // English (UK)
    Locale('es', 'ES'), // Spanish
    Locale('fr', 'FR'), // French
    Locale('de', 'DE'), // German
    Locale('ja', 'JP'), // Japanese
    Locale('zh', 'CN'), // Chinese (Simplified)
    Locale('ko', 'KR'), // Korean
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('hi', 'IN'), // Hindi
  ];

  /// Default locale.
  static const Locale defaultLocale = Locale('en', 'US');

  /// Returns the locale name for display.
  static String getDisplayName(Locale locale) {
    return switch (locale.languageCode) {
      'en' => locale.countryCode == 'GB' ? 'English (UK)' : 'English (US)',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'ja' => '日本語',
      'zh' => '中文（简体）',
      'ko' => '한국어',
      'pt' => 'Português (Brasil)',
      'hi' => 'हिन्दी',
      _ => locale.languageCode,
    };
  }
}
