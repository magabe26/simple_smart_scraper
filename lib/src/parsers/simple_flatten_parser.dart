/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:petitparser/petitparser.dart';

class SimpleFlattenParser extends DelegateParser<String> {
  final String message;
  SimpleFlattenParser(Parser<String> delegate, [this.message])
      : super(delegate);

  @override
  Result<String> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Success<String>) {
      return result;
    } else {
      if (message == null) {
        return result;
      } else {
        return result.failure(message);
      }
    }
  }

  @override
  int fastParseOn(String buffer, int position) {
    return delegate.fastParseOn(buffer, position);
  }

  @override
  bool hasEqualProperties(FlattenParser other) =>
      identical(this, other) ||
      other is SimpleFlattenParser &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  SimpleFlattenParser copy() => SimpleFlattenParser(delegate);
}
