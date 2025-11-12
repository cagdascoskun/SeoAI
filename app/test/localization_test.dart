import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seoai/core/localization/app_localizations.dart';

void main() {
  test('AppLocalizations returns Turkish fallback', () {
    const locale = Locale('tr');
    final loc = AppLocalizations(locale);
    expect(loc.translate('app_name'), equals('AI SEO Tagger'));
    expect(loc.translate('unknown_key'), equals('unknown_key'));
  });
}
