/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:simple_smart_scraper/src/parsers/simple_flatten_parser.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';

import 'parsers.dart';

/// Parse text except children elements
class ElementTextParser extends Parser<String> {
  String tag;
  ElementTextParser(this.tag);

  @override
  Parser<String> copy() {
    return ElementTextParser(tag);
  }

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  @override
  Result<String> parseOn(Context context) {
    // ignore: omit_local_variable_types
    final int position = context.position;
    // ignore: omit_local_variable_types
    final String buffer = context.buffer;

    if (position < buffer.length) {
      // ignore: omit_local_variable_types
      final String input = buffer.substring(position);
      var result = parsers.getParserResult(
          parser: parsers.qualifiedElement(tag), input: input);
      if (result.isEmpty) {
        return Failure<String>(
            buffer, position, 'No element with $tag tag found.');
      }
      // ignore: omit_local_variable_types
      final int index = buffer.indexOf(result, position);
      if (index == -1) {
        return Failure<String>(buffer, position,
            'Failed to parse, No element with $tag tag found.');
      }
      final newPosition = index + result.length;

      var value;
      try {
        value = parsers.strip(result);
        final isText = (!parsers.childrenElements().accept(value));
        if (isText) {
          return Success<String>(buffer, newPosition, value);
        } else {
          final children = parsers.getParserResults(
              parser: parsers.childrenElements(), input: value);
          final childrenCount = children.length;
          if (childrenCount == 1) {
            final isClosed = parsers
                .elementStartTag(isClosed: true)
                .accept(children.elementAt(0));
            if (isClosed) {
              return Failure<String>(buffer, newPosition,
                  '$tag does not contain text, but a closed element \n>>> ${children.elementAt(0)} <<<');
            } else {
              return Failure<String>(buffer, newPosition,
                  '$tag does not contain text, but an element \n>>> ${children.elementAt(0)} <<<');
            }
          } else if (childrenCount > 1) {
            return Failure<String>(buffer, newPosition,
                '$tag does not contain text, but $childrenCount elements \n>>> $children <<<');
          } else {
            return Failure<String>(
                buffer, newPosition, '$tag does not contain any text');
          }
        }
      } on StripException catch (_) {
        final isClosed =
            parsers.elementStartTag(isClosed: true).accept(_.output);
        if (isClosed) {
          return Failure<String>(buffer, newPosition,
              '$tag is a closed element, therefore does not contain text \n>>> ${_.output} <<<');
        } else {
          return Failure<String>(buffer, newPosition, '$tag striping failed.');
        }
      }
    } else {
      return Failure<String>(buffer, buffer.length,
          'Failed to get text, position > buffer.length.');
    }
  }
}
