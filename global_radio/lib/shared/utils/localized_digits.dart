/// Converts ASCII digits in a string to the numeral script of the given
/// language code (e.g. '12:30' → '१२:३०' for Hindi). Unknown languages
/// return the text unchanged.
library;

const Map<String, String> _digitSets = {
  'hi': '०१२३४५६७८९', // Devanagari
  'mr': '०१२३४५६७८९',
  'bn': '০১২৩৪৫৬৭৮৯', // Bengali
  'gu': '૦૧૨૩૪૫૬૭૮૯', // Gujarati
  'kn': '೦೧೨೩೪೫೬೭೮೯', // Kannada
  'ml': '൦൧൨൩൪൫൬൭൮൯', // Malayalam
  'ta': '௦௧௨௩௪௫௬௭௮௯', // Tamil
  'te': '౦౧౨౩౪౫౬౭౮౯', // Telugu
  'ur': '۰۱۲۳۴۵۶۷۸۹', // Urdu (Eastern Arabic)
};

String localizeDigits(String text, String? languageCode) {
  final digits = _digitSets[languageCode];
  if (digits == null) return text;
  final buf = StringBuffer();
  for (final unit in text.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      buf.write(digits[unit - 0x30]);
    } else {
      buf.writeCharCode(unit);
    }
  }
  return buf.toString();
}
