import '../combinators/choice.dart';
import '../combinators/sequence.dart';
import 'result.dart';
import '../parser.dart';

/// Models a group of operators of the same precedence.
class ExpressionGroup {
  final Parser _loopback;

  ExpressionGroup(this._loopback);

  /// Defines a new primitive or literal [parser]. Evaluates the optional
  /// [action].
  void primitive<V>(Parser<V> parser, [Object Function(V value) action]) {
    _primitives.add(action != null ? parser.map(action) : parser);
  }

  Parser _buildPrimitive(Parser inner) {
    return _buildChoice(_primitives, inner);
  }

  final List<Parser> _primitives = [];

  /// Defines a new wrapper using [left] and [right] parsers, that are typically
  /// used for parenthesis. Evaluates the optional [action] with the parsed
  /// `left` delimiter, the `value` and `right` delimiter.
  void wrapper<O, V>(Parser<O> left, Parser<O> right,
      [Object Function(O left, V value, O right) action]) {
    action ??= (left, value, right) => [left, value, right];
    _wrappers.add(SequenceParser([left, _loopback, right])
        .map((value) => action(value[0], value[1], value[2])));
  }

  Parser _buildWrapper(Parser inner) {
    return _buildChoice([..._wrappers, inner], inner);
  }

  final List<Parser> _wrappers = [];

  /// Adds a prefix operator [parser]. Evaluates the optional [action] with the
  /// parsed `operator` and `value`.
  void prefix<O, V>(Parser<O> parser,
      [Object Function(O operator, V value) action]) {
    action ??= (operator, value) => [operator, value];
    _prefix.add(parser.map((operator) => ExpressionResult(operator, action)));
  }

  Parser _buildPrefix(Parser inner) {
    if (_prefix.isEmpty) {
      return inner;
    } else {
      return SequenceParser([_buildChoice(_prefix).star(), inner]).map((tuple) {
        return tuple.first.reversed.fold(tuple.last, (value, result) {
          final ExpressionResult expressionResult = result;
          return expressionResult.action(expressionResult.operator, value);
        });
      });
    }
  }

  final List<Parser> _prefix = [];

  /// Adds a postfix operator [parser]. Evaluates the optional [action] with the
  /// parsed `value` and `operator`.
  void postfix<O, V>(Parser<O> parser,
      [Object Function(V value, O operator) action]) {
    action ??= (value, operator) => [value, operator];
    _postfix.add(parser.map((operator) => ExpressionResult(operator, action)));
  }

  Parser _buildPostfix(Parser inner) {
    if (_postfix.isEmpty) {
      return inner;
    } else {
      return SequenceParser([inner, _buildChoice(_postfix).star()])
          .map((tuple) {
        return tuple.last.fold(tuple.first, (value, result) {
          final ExpressionResult expressionResult = result;
          return expressionResult.action(value, expressionResult.operator);
        });
      });
    }
  }

  final List<Parser> _postfix = [];

  /// Adds a right-associative operator [parser]. Evaluates the optional
  /// [action] with the parsed `left` term, `operator`, and `right` term.
  void right<O, V>(Parser<O> parser,
      [Object Function(V left, O operator, V right) action]) {
    action ??= (left, operator, right) => [left, operator, right];
    _right.add(parser.map((operator) => ExpressionResult(operator, action)));
  }

  Parser _buildRight(Parser inner) {
    if (_right.isEmpty) {
      return inner;
    } else {
      return inner.separatedBy(_buildChoice(_right)).map((sequence) {
        var result = sequence.last;
        for (var i = sequence.length - 2; i > 0; i -= 2) {
          final ExpressionResult expressionResult = sequence[i];
          result = expressionResult.action(
              sequence[i - 1], expressionResult.operator, result);
        }
        return result;
      });
    }
  }

  final List<Parser> _right = [];

  /// Adds a left-associative operator [parser]. Evaluates the optional [action]
  /// with the parsed `left` term, `operator`, and `right` term.
  void left<O, V>(Parser<O> parser,
      [Object Function(V left, O operator, V right) action]) {
    action ??= (left, operator, right) => [left, operator, right];
    _left.add(parser.map((operator) => ExpressionResult(operator, action)));
  }

  Parser _buildLeft(Parser inner) {
    if (_left.isEmpty) {
      return inner;
    } else {
      return inner.separatedBy(_buildChoice(_left)).map((sequence) {
        var result = sequence.first;
        for (var i = 1; i < sequence.length; i += 2) {
          final ExpressionResult expressionResult = sequence[i];
          result = expressionResult.action(
              result, expressionResult.operator, sequence[i + 1]);
        }
        return result;
      });
    }
  }

  final List<Parser> _left = [];

  // helper to build an optimal choice parser
  Parser _buildChoice(List<Parser> parsers, [Parser otherwise]) {
    if (parsers.isEmpty) {
      return otherwise;
    } else if (parsers.length == 1) {
      return parsers.first;
    } else {
      return ChoiceParser(parsers);
    }
  }

  // helper to build the group of parsers
  Parser build(Parser inner) {
    return _buildLeft(_buildRight(
        _buildPostfix(_buildPrefix(_buildWrapper(_buildPrimitive(inner))))));
  }
}
