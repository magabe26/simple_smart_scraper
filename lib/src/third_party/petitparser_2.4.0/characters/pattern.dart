import 'char.dart';
import 'code.dart';
import 'not.dart';
import 'optimize.dart';
import 'parser.dart';
import 'predicate.dart';
import 'range.dart';
import '../parser.dart';
import '../predicates/any.dart';

/// Returns a parser that accepts the given character class pattern.
Parser<String> pattern(String element, [String message]) {
  return CharacterParser(pattern_.parse(element).value,
      message ?? '[${toReadableString(element)}] expected');
}

/// Parser that reads a single character.
final Parser<RangeCharPredicate> single_ =
    any().map((element) => RangeCharPredicate(
          toCharCode(element),
          toCharCode(element),
        ));

/// Parser that reads a character range.
final Parser<RangeCharPredicate> range_ =
    any().seq(char('-')).seq(any()).map((elements) => RangeCharPredicate(
          toCharCode(elements[0]),
          toCharCode(elements[2]),
        ));

/// Parser that reads a sequence of single characters or ranges.
final Parser<CharacterPredicate> sequence_ = range_.or(single_).plus().map(
    (predicates) => optimizedRanges(predicates.cast<RangeCharPredicate>()));

/// Parser that reads a possibly negated sequecne of predicates.
final Parser<CharacterPredicate> pattern_ = char('^')
    .optional()
    .seq(sequence_)
    .map((predicates) => predicates[0] == null
        ? predicates[1]
        : NotCharacterPredicate(predicates[1]));
