import 'result.dart';

/// An immutable parse result in case of a successful parse.
class Success<R> extends Result<R> {
  const Success(String buffer, int position, this.value)
      : super(buffer, position);

  @override
  bool get isSuccess => true;

  @override
  final R value;

  @override
  String get message => null;

  @override
  Result<T> map<T>(T Function(R element) callback) => success(callback(value));

  @override
  String toString() => 'Success[${toPositionString()}]: $value';
}
