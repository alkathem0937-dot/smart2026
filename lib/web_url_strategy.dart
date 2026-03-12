// ملف لإعداد URL strategy على الويب فقط
// File to configure URL strategy on web only

import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import - يعمل فقط على الويب
// Conditional import - works only on web
// على الويب: يستورد flutter_web_plugins
// على Android/iOS: يستورد web_url_strategy_stub.dart
import 'package:flutter_web_plugins/flutter_web_plugins.dart' 
    if (dart.library.io) 'web_url_strategy_stub.dart';

void configureWebUrlStrategy() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
}
