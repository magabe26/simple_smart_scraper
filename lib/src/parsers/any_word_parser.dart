/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';
import 'package:simple_smart_scraper/src/parsers/simple_flatten_parser.dart';

import 'parsers.dart';

///Parses any word except the provided exceptionalWords with caseSensitivity capabilities
class AnyWordParser extends Parser<String> {
  final Set<String> exceptionalWords;
  final bool caseSensitive;

  AnyWordParser({@required Set<String> except, bool caseSensitive = true})
      : exceptionalWords = except ?? <String>{},
        caseSensitive = caseSensitive;

  @override
  Parser<String> copy() {
    return AnyWordParser(except: exceptionalWords);
  }

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  bool isExceptional(String word) {
    if (caseSensitive) {
      return exceptionalWords.contains(word);
    } else {
      Parser matcher(String word) => parsers.nonCaseSensitiveChars(word);
      for (var exceptional in exceptionalWords) {
        if (matcher(exceptional).accept(word)) {
          return true;
        }
      }
      return false;
    }
  }

  @override
  Result<String> parseOn(Context context) {
    final buffer = context.buffer;
    // ignore: omit_local_variable_types
    int position = context.position;

    if (position > buffer.length) {
      return failure(
        buffer: buffer,
        error: 'Failed , reached the end of buffer',
      );
    }

    while (position < buffer.length) {
      var value = parsers.getParserResult(
          parser: word().plus(), input: buffer.substring(position));
      if (value.isNotEmpty) {
        final index = buffer.indexOf(value, position);
        if (index < 0) {
          return failure(
            buffer: buffer,
            error: '1. No word found',
          );
        }

        //update position
        position = index + value.length;

        if (!isExceptional(value)) {
          return Success<String>(buffer, position, value);
        }
      } else {
        return failure(
          buffer: buffer,
          error: '2. No word found',
        );
      }
    }
    return failure(
      buffer: buffer,
      error: '3. No word found',
    );
  }

  Result<String> failure({
    @required String buffer,
    @required String error,
  }) {
    return Failure<String>(buffer, buffer.length, error);
  }
}
