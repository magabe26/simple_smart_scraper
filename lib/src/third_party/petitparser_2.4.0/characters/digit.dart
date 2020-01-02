import 'parser.dart';
import 'predicate.dart';
import '../parser.dart';

/// Returns a parser that accepts any digit character.
Parser<String> digit([String message = 'digit expected']) {
  return CharacterParser(const DigitCharPredicate(), message);
}

class DigitCharPredicate extends CharacterPredicate {
  const DigitCharPredicate();

  @override
  bool test(int value) => 48 <= value && value <= 57;

  @override
  bool isEqualTo(CharacterPredicate other) => other is DigitCharPredicate;
}
