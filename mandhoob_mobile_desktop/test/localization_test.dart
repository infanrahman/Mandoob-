import 'dart:ui';
import 'package:mandhoob_app/core/localization/app_localizations.dart';

void main() {
  print('=============================================');
  print('TESTING APP LOCALIZATION & LANGUAGE SWITCHING');
  print('=============================================');

  final lang = AppLanguage();

  // Test 1: Default English state
  assert(lang.isArabic == false, 'Expected default isArabic == false');
  assert(lang.locale.languageCode == 'en', 'Expected languageCode == en');
  assert(lang.textDirection == TextDirection.ltr, 'Expected textDirection == ltr');
  assert(lang.translate('dashboard') == 'Dashboard', 'Expected English translation for dashboard');
  assert(lang.translate('sales') == 'Sales & Invoicing', 'Expected English translation for sales');
  print('>>> 1. Default English (LTR) State: PASSED! <<<');
  print('   Language Code: ${lang.locale.languageCode}');
  print('   Direction: ${lang.textDirection}');
  print('   Dashboard Title: ${lang.translate('dashboard')}');

  // Test 2: Toggle to Arabic
  lang.toggleLanguage();
  assert(lang.isArabic == true, 'Expected isArabic == true after toggle');
  assert(lang.locale.languageCode == 'ar', 'Expected languageCode == ar after toggle');
  assert(lang.textDirection == TextDirection.rtl, 'Expected textDirection == rtl after toggle');
  assert(lang.translate('dashboard') == 'الرئيسية', 'Expected Arabic translation for dashboard');
  assert(lang.translate('sales') == 'المبيعات والفوترة', 'Expected Arabic translation for sales');
  print('\n>>> 2. Toggled to Arabic (RTL): PASSED! <<<');
  print('   Language Code: ${lang.locale.languageCode}');
  print('   Direction: ${lang.textDirection}');
  print('   Dashboard Title: ${lang.translate('dashboard')}');

  // Test 3: Toggle back to English
  lang.toggleLanguage();
  assert(lang.isArabic == false, 'Expected isArabic == false after second toggle');
  assert(lang.locale.languageCode == 'en', 'Expected languageCode == en');
  assert(lang.textDirection == TextDirection.ltr, 'Expected textDirection == ltr');
  print('\n>>> 3. Toggled Back to English (LTR): PASSED! <<<');
  print('   Dashboard Title: ${lang.translate('dashboard')}');

  // Test 4: Static helper AppLanguage.tr
  lang.setLocale(const Locale('en'));
  assert(AppLanguage.tr('customers') == 'Customers & Receivables');
  lang.setLocale(const Locale('ar'));
  assert(AppLanguage.tr('customers') == 'العملاء والذمم');
  print('\n>>> 4. Static Helper AppLanguage.tr: PASSED! <<<');

  print('\n=============================================');
  print('ALL LOCALIZATION TESTS PASSED 100%!');
  print('=============================================');
}
