/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:simple_smart_scraper/petitparser_2.4.0.dart';
import 'simple_flatten_parser.dart';

///The parser that allow the parsing process to be intercepted by the [Interceptor]

typedef Interceptor = String Function(String input);

class InterceptedParser extends Parser<String> {
  final Interceptor interceptor;

  InterceptedParser(this.interceptor);

  @override
  Parser<String> copy() {
    return InterceptedParser(interceptor);
  }

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  @override
  Result<String> parseOn(Context context) {
    if (context.position < context.buffer.length) {
      final value = (interceptor == null) ? '' : interceptor(context.buffer);
      return Success<String>(
          context.buffer, context.buffer.length, (value == null) ? '' : value);
    } else {
      return Failure<String>(context.buffer, context.buffer.length,
          'Failed , reached the end of buffer');
    }
  }
}
