/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:petitparser/petitparser.dart';
import 'package:simple_smart_scraper/src/parsers/simple_flatten_parser.dart';

///[ForwardParser] don't parse input,  but return the same input as result
class ForwardParser extends Parser<String> {
  @override
  Parser<String> copy() {
    return ForwardParser();
  }

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  @override
  Result<String> parseOn(Context context) {
    if (context.position < context.buffer.length) {
      return Success<String>(
          context.buffer, context.buffer.length, context.buffer);
    } else {
      return Failure<String>(context.buffer, context.buffer.length,
          'Failed , reached the end of buffer');
    }
  }
}
