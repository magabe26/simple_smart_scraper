import 'code.dart';
import 'not.dart';
import 'optimize.dart';
import 'parser.dart';
import '../parser.dart';

/// Returns a parser that accepts none of the specified characters.
Parser<String> noneOf(String chars, [String message]) {
  return CharacterParser(NotCharacterPredicate(optimizedString(chars)),
      message ?? 'none of "${toReadableString(chars)}" expected');
}
