import '../parser.dart';
import 'predicate.dart';

/// Returns a parser that accepts the string [element].
///
/// For example, `string('foo')` succeeds and consumes the input string
/// `'foo'`. Fails for any other input.
Parser<String> string(String element, [String message]) {
  return predicate(element.length, (each) => element == each,
      message ?? '$element expected');
}

/// Returns a parser that accepts the string [element] ignoring the case.
///
/// For example, `stringIgnoreCase('foo')` succeeds and consumes the input
/// string `'Foo'` or `'FOO'`. Fails for any other input.
Parser<String> stringIgnoreCase(String element, [String message]) {
  final lowerElement = element.toLowerCase();
  return predicate(element.length, (each) => lowerElement == each.toLowerCase(),
      message ?? '$element expected');
}
