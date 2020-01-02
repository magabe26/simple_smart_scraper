import '../combinators/delegate.dart';
import '../contexts/context.dart';
import '../contexts/result.dart';
import '../parser.dart';
import '../token.dart';

/// A parser that answers a token of the result its delegate parses.
class TokenParser<T> extends DelegateParser<Token<T>> {
  TokenParser(Parser delegate) : super(delegate);

  @override
  Result<Token<T>> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result.isSuccess) {
      final token = Token<T>(
          result.value, context.buffer, context.position, result.position);
      return result.success(token);
    } else {
      return result.failure(result.message);
    }
  }

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  TokenParser<T> copy() => TokenParser<T>(delegate);
}
