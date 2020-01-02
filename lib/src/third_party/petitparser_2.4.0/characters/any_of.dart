import 'code.dart';
import 'optimize.dart';
import 'parser.dart';
import '../parser.dart';

/// Returns a parser that accepts any of the specified characters.
Parser<String> anyOf(String chars, [String message]) {
  return CharacterParser(optimizedString(chars),
      message ?? 'any of "${toReadableString(chars)}" expected');
}
