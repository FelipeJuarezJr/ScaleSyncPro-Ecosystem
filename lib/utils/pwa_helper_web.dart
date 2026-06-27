// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

bool isPwaSupported() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('chrome') ||
      userAgent.contains('safari') ||
      userAgent.contains('firefox') ||
      userAgent.contains('edge') ||
      userAgent.contains('opera');
}

bool isPwaInstalled() {
  try {
    if (js.context.hasProperty('isAppInstalled')) {
      return js.context.callMethod('isAppInstalled') as bool;
    }
  } catch (_) {}
  return false;
}

bool triggerPwaInstall() {
  try {
    if (js.context.hasProperty('presentInstallPrompt')) {
      return js.context.callMethod('presentInstallPrompt') as bool;
    }
  } catch (_) {}
  return false;
}

void registerInstallableCallback(void Function() callback) {
  try {
    js.context['onAppInstallable'] = callback;
  } catch (_) {}
}
