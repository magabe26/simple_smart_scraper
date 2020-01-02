import 'exception.dart';
import 'result.dart';

/// An immutable parse result in case of a failed parse.
class Failure<R> extends Result<R> {
  const Failure(String buffer, int position, this.message)
      : super(buffer, position);

  @override
  bool get isFailure => true;

  @override
  R get value => throw ParserException(this);

  @override
  final String message;

  @override
  Result<T> map<T>(T Function(R element) callback) => failure(message);

  @override
  String toString() => 'Failure[${toPositionString()}]: $message';
}
