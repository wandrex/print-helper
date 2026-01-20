import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/db_service.dart';
import '../services/helpers.dart';
import '../utils/console_util.dart';
import '../widgets/loaders.dart';

enum Locales { english, arabic }

class LangPro extends ChangeNotifier {
  static final LangPro instance = LangPro._();
  LangPro._();

  Locales _locale = Locales.english;
  Locales get locale => _locale;

  Future<bool> checkOnboarding() async {
    final isOnboarded = await DbService.isOnboarded();
    if (isOnboarded) await getLocale();
    printData(data: 'Onboarded status:  $isOnboarded');
    return isOnboarded;
  }

  Future<void> getLocale() async {
    _locale = await DbService.getLocale();
    printData(title: 'loaded locale is', data: _locale.name);
    notifyListeners();
  }

  Future<void> changeLocale(Locales locale, BuildContext ctx) async {
    try {
      Loaders.show();
      await delayed(
        callback: () async {
          if (locale == Locales.english) {
            await ctx.setLocale(const Locale('en', 'US'));
            await DbService.setLocale(Locales.english);
          } else {
            await ctx.setLocale(const Locale('ar', 'QA'));
            await DbService.setLocale(Locales.arabic);
          }
          await getLocale();
        },
      );
      // TODO: clear filters or associated data
      // if (ctx.mounted) getBookingPro(ctx).clearFilters();
      Loaders.hide();
      printData(title: 'locale selected as', data: locale.name);
    } catch (e, st) {
      printData(title: 'from changeLocale', data: '$e\n$st', e: true);
    }
  }
}
