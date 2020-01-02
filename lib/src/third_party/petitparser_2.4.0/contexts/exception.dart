import 'failure.dart';

/// An exception raised in case of a parse error.
class ParserException implements Exception {
  final Failure failure;

  ParserException(this.failure);

  @override
  String toString() => '${failure.message} at ${failure.toPositionString()}';
}
