import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocaleController extends GetxController {
  final Rx<Locale> locale = const Locale('en').obs;

  void changeLocale(String languageCode) {
    final newLocale = Locale(languageCode);
    locale.value = newLocale;
    Get.updateLocale(newLocale);
  }
}


