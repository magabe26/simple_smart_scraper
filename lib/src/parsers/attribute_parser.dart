/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'parsers.dart';
import 'simple_flatten_parser.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';

///Parses attributes, if caseSensitive is set to false then case sensitivity is ignored,  for-example href will match HREF, hREF , Href etc
///And due to the characteristics of a parser returned by nonCaseSensitiveChars(), hrefXXX will also match HREF, hREF , Href etc
class AttributeParser extends Parser<String> {
  final String attributeKey;
  final hasValue;
  final bool caseSensitive;

  AttributeParser(
    this.attributeKey, {
    bool hasValue = true,
    bool caseSensitive = true,
  })  : hasValue = hasValue,
        caseSensitive = caseSensitive;

  @override
  Parser<String> copy() {
    return AttributeParser(attributeKey);
  }

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  Parser _attributesWithValue() {
    final key =
        letter().plus().seq((letter() | digit() | pattern('-_~.')).star());
    final attrKey = key.seq(parsers.spaceOptional());
    final withValue = parsers
        .equal()
        .seq(parsers.spaceOptional())
        .seq(parsers.attributeValue());

    return attrKey.seq(withValue);
  }

  List<Map<String, String>> toAttributeMaps(List<String> attributes) {
    // ignore: omit_local_variable_types
    Map<String, String> attributeKeyAttributeValueMap = <String, String>{};
    // ignore: omit_local_variable_types
    Map<String, String> attributeKeyAttributeStringMap = <String, String>{};
    for (var attributeString in attributes) {
      attributeString = attributeString.trim();
      if (attributeString.isNotEmpty) {
        final index = attributeString.indexOf('=', 0);
        if (index >= 0) {
          final key = attributeString.substring(0, index).trim();
          final value =
              parsers.removeQuotes(attributeString.substring(index + 1));

          if (key.isNotEmpty) {
            //value can be null
            attributeKeyAttributeValueMap[key] = value;
            attributeKeyAttributeStringMap[key] = attributeString;
          }
        }
      }
    }
    return [attributeKeyAttributeValueMap, attributeKeyAttributeStringMap];
  }

  Parser matcher(String word) => parsers.nonCaseSensitiveChars(word);

  @override
  Result<String> parseOn(Context context) {
    // ignore: omit_local_variable_types
    final String buffer = context.buffer;
    var position = context.position;

    if (position < buffer.length) {
      // ignore: omit_local_variable_types
      int end = buffer.indexOf('>', position);
      if (end >= 0) {
        // ignore: omit_local_variable_types
        String attributeContent =
            buffer.substring(position, end + 1); // 1 is the length of >

        if (attributeContent.isNotEmpty) {
          final tagStr = parsers.getParserResult(
              parser: parsers
                  .start()
                  .seq(parsers.spaceOptional())
                  .seq(letter().seq((letter() | digit()).star()))
                  .seq(parsers.spaceOptional()),
              input: attributeContent);

          if (tagStr.isNotEmpty) {
            // final tag = tagStr.replaceAll('<', '').trim();
            attributeContent = attributeContent.replaceAll(tagStr, '');
          }

          attributeContent = attributeContent.replaceAll('>', '');
          if (attributeContent.isNotEmpty) {
            final attributesWithValues = parsers.getParserResults(
                parser: _attributesWithValue(), input: attributeContent);

            // ignore: omit_local_variable_types
            String _tmp = attributeContent;
            attributesWithValues.forEach((attr) {
              _tmp = _tmp.replaceAll(attr, '');
            });
            if (_tmp.trim() == '/') {
              _tmp = '';
            } else {
              _tmp = _tmp.trim();
            }

            // ignore: omit_local_variable_types
            List<String> attributesWithNoValuesList = _tmp.split('\s');

            final attributeMaps = toAttributeMaps(attributesWithValues);

            // ignore: omit_local_variable_types
            final Map<String, String> attributeKeyAttributeValueMap =
                attributeMaps[0];

            // ignore: omit_local_variable_types
            final Map<String, String> attributeKeyAttributeStringMap =
                attributeMaps[1];

            if (hasValue) {
              for (var _attributeKey in attributeKeyAttributeValueMap.keys) {
                bool match;
                if ((attributeKey == null)) {
                  match = true;
                } else {
                  match = (caseSensitive
                      ? (_attributeKey == attributeKey)
                      : matcher(_attributeKey).accept(attributeKey));
                }

                final attributesString =
                    attributeKeyAttributeStringMap[_attributeKey];

                final index = buffer.indexOf(attributesString, position);
                if (index >= 0) {
                  //update position
                  position = index + attributesString.length;
                  if (match) {
                    return Success<String>(buffer, position, attributesString);
                  }
                }
              }
            } else {
              for (var _attributeKey in attributesWithNoValuesList) {
                bool match;
                if ((attributeKey == null)) {
                  match = true;
                } else {
                  match = (caseSensitive
                      ? (_attributeKey == attributeKey)
                      : matcher(_attributeKey).accept(attributeKey));
                }

                final attributesString = _attributeKey;
                var index = buffer.indexOf(attributesString, position);
                if (index >= 0) {
                  //update position
                  position = index + attributesString.length;
                  if (match) {
                    return Success<String>(buffer, position, attributesString);
                  }
                }
              }
            }
          }
        }
      }

      return Failure<String>(
          context.buffer, position, 'Failed , No attribute found');
    } else {
      return Failure<String>(context.buffer, context.buffer.length,
          'Failed , reached the end of buffer');
    }
  }
}
