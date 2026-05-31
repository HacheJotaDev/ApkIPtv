/// Utility class to clean and normalize text from IPTV sources
/// Handles BOM, HTML entities, URL encoding, emoji, and other encoding issues
class TextUtils {
  /// Clean text from IPTV sources - removes weird symbols and normalizes
  static String cleanText(String? input) {
    if (input == null || input.isEmpty) return '';

    String text = input;

    // Remove BOM (Byte Order Mark) - UTF-8, UTF-16 BE, UTF-16 LE
    text = text.replaceAll('\uFEFF', ''); // UTF-8 BOM
    text = text.replaceAll('\uFFFE', ''); // Reversed BOM
    text = text.replaceAll('\u0000', ''); // Null bytes

    // Remove other zero-width characters
    text = text.replaceAll('\u200B', ''); // Zero-width space
    text = text.replaceAll('\u200C', ''); // Zero-width non-joiner
    text = text.replaceAll('\u200D', ''); // Zero-width joiner

    // Remove control characters (keep newline and tab)
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      // Keep printable characters, newlines, tabs, and characters above Latin Extended
      if (codeUnit >= 32 || codeUnit == 10 || codeUnit == 13 || codeUnit == 9) {
        buffer.writeCharCode(codeUnit);
      } else if (codeUnit >= 0x0080) {
        // Keep extended characters (accented, CJK, emoji, etc.)
        buffer.writeCharCode(codeUnit);
      }
      // Skip control chars (0x00-0x1F except tab/newline, and 0x7F DEL)
    }
    text = buffer.toString();

    // Decode common HTML entities
    text = _decodeHtmlEntities(text);

    // Decode URL encoding if present (e.g., %20, %C3%A1)
    if (text.contains('%') && _looksUrlEncoded(text)) {
      try {
        text = Uri.decodeComponent(text);
      } catch (_) {
        // If decoding fails, keep original
      }
    }

    // Normalize whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Decode common HTML entities found in IPTV metadata
  static String _decodeHtmlEntities(String text) {
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&aacute;': 'a',
      '&eacute;': 'e',
      '&iacute;': 'i',
      '&oacute;': 'o',
      '&uacute;': 'u',
      '&ntilde;': 'n',
      '&Aacute;': 'A',
      '&Eacute;': 'E',
      '&Iacute;': 'I',
      '&Oacute;': 'O',
      '&Uacute;': 'U',
      '&Ntilde;': 'N',
    };

    for (final entry in entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // Decode numeric HTML entities like &#225; or &#x00E1;
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final code = int.tryParse(match.group(1) ?? '');
        if (code != null && code > 0) {
          return String.fromCharCode(code);
        }
        return match.group(0) ?? '';
      },
    );
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        final code = int.tryParse(match.group(1) ?? '', radix: 16);
        if (code != null && code > 0) {
          return String.fromCharCode(code);
        }
        return match.group(0) ?? '';
      },
    );

    return text;
  }

  /// Check if the text looks like it contains URL encoding
  static bool _looksUrlEncoded(String text) {
    int percentCount = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '%') percentCount++;
    }
    // If more than 5% of characters are %, it's likely URL encoded
    return percentCount > (text.length * 0.05);
  }
}
