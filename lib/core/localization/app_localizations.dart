import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/localization/translations/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Convenience getter
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get login => translate('login');
  String get register => translate('register');
  String get phoneNumber => translate('phone_number');
  String get password => translate('password');
  String get enterPhone => translate('enter_phone');
  String get enterPassword => translate('enter_password');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get signUp => translate('sign_up');
  String get signIn => translate('sign_in');
  String get customer => translate('customer');
  String get provider => translate('provider');
  String get selectRole => translate('select_role');
  String get continueAsCustomer => translate('continue_as_customer');
  String get continueAsProvider => translate('continue_as_provider');
  String get verifyOTP => translate('verify_otp');
  String get enterOTP => translate('enter_otp');
  String get resendOTP => translate('resend_otp');
  String get verify => translate('verify');
  String get dashboard => translate('dashboard');
  String get bookings => translate('bookings');
  String get services => translate('services');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get notifications => translate('notifications');
  String get search => translate('search');
  String get filter => translate('filter');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get confirm => translate('confirm');
  String get back => translate('back');
  String get next => translate('next');
  String get skip => translate('skip');
  String get done => translate('done');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get info => translate('info');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get submit => translate('submit');
  String get close => translate('close');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'bn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
