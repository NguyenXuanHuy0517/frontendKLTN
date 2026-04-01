import 'dart:convert';

String fixVietnameseEncoding(String text) {
  const mojibakeMarkers = ['Ã', 'â', 'Æ', 'Ä', 'á»'];
  if (!mojibakeMarkers.any(text.contains)) return text;

  try {
    return utf8.decode(latin1.encode(text));
  } catch (_) {
    return text;
  }
}

extension VietnameseTextX on String {
  String get vi => fixVietnameseEncoding(this);
}
