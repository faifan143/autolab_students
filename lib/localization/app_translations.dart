import 'package:get/get.dart';

import 'en.dart';
import 'ar.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enTranslations,
        'ar': arTranslations,
      };
}


