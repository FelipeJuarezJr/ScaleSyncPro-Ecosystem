import 'dart:html' as html;
import 'domain_guard.dart';

class DomainGuard {
  static AppViewTarget get currentTarget {
    try {
      final port = html.window.location.port;
      final host = html.window.location.hostname?.toLowerCase() ?? '';

      if (host.contains('marketplace') || port == '8082') {
        return AppViewTarget.market;
      }
      if (host.contains('social') || port == '8083') {
        return AppViewTarget.social;
      }
    } catch (_) {}
    return AppViewTarget.pro;
  }
}
