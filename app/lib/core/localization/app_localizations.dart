import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const _values = <String, Map<String, String>>{
    'tr': {
      'app_name': 'AI SEO Tagger',
      'sign_in': 'Sign In',
      'email': 'Email',
      'send_magic_link': 'Send Magic Link',
      'dashboard': 'Dashboard',
      'new_analysis': 'New Analysis',
      'batch_analysis': 'Batch Analysis',
      'credits': 'Credits',
      'settings': 'Settings',
      'about': 'About',
      'logout': 'Logout',
      'description': 'Description',
      'title_optional': 'Product Title (optional)',
      'choose_image': 'Select Image',
      'analyze': 'Analyze',
      'language': 'Language',
      'channel': 'Channel',
      'credit_warning': 'Not enough credits. Please purchase a pack.',
      'faq': 'FAQ',
      'export': 'Export',
      'download_csv': 'Download CSV',
      'download_json': 'Download JSON',
      'competitors': 'Competitors',
      'attributes': 'Attributes',
      'seo_recommendations': 'SEO Recommendations',
      'copy': 'Copy',
      'upload_csv': 'Upload CSV',
      'queue_status': 'Queue Status',
      'purchase_credits': 'Purchase Credits',
      'language_tr': 'Turkish',
      'language_en': 'English',
    },
    'en': {
      'app_name': 'AI SEO Tagger',
      'sign_in': 'Sign In',
      'email': 'Email',
      'send_magic_link': 'Send Magic Link',
      'dashboard': 'Dashboard',
      'new_analysis': 'New Analysis',
      'batch_analysis': 'Batch Analysis',
      'credits': 'Credits',
      'settings': 'Settings',
      'about': 'About',
      'logout': 'Logout',
      'description': 'Description',
      'title_optional': 'Product Title (optional)',
      'choose_image': 'Select Image',
      'analyze': 'Analyze',
      'language': 'Language',
      'channel': 'Channel',
      'credit_warning': 'Not enough credits. Purchase more.',
      'faq': 'FAQ',
      'export': 'Export',
      'download_csv': 'Download CSV',
      'download_json': 'Download JSON',
      'competitors': 'Competitors',
      'attributes': 'Attributes',
      'seo_recommendations': 'SEO Recommendations',
      'copy': 'Copy',
      'upload_csv': 'Upload CSV',
      'queue_status': 'Queue Status',
      'purchase_credits': 'Purchase Credits',
      'language_tr': 'Turkish',
      'language_en': 'English',
    },
  };

  static const supportedLocales = [Locale('tr'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String translate(String key) {
    final lang = _values[locale.languageCode] ?? _values['tr']!;
    return lang[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
