// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> setStorageItem(String key, String value) async {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

Future<String?> getStorageItem(String key) async {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

Future<void> removeStorageItem(String key) async {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}

