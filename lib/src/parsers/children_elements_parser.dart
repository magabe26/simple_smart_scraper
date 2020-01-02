/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'parsers.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';

/// Parse any children elements except text and provided exceptionalTags
class ChildrenElementsParser extends Parser {
  Set<String> _tags;
  Parser _mainParser;
  Set<String> exceptionalTags;
  @override
  ChildrenElementsParser(this.exceptionalTags);

  @override
  Parser copy() {
    return _mainParser ?? ChildrenElementsParser(exceptionalTags);
  }

  @override
  Result parseOn(Context context) {
    _tags ??= parsers.getElementTags(context.buffer);

    if (_mainParser == null) {
      for (var tag in _tags) {
        var parser = parsers
            .spaceOptional()
            .seq((parsers.element(tag) |
                parsers.elementStartTag(tag: tag, isClosed: true) |
                parsers.elementStartTag(tag: tag)))
            .seq(parsers.spaceOptional());

        if (_mainParser == null) {
          _mainParser = parser;
        } else {
          _mainParser = _mainParser.or(parser);
        }
      }
    }
    return (_mainParser != null)
        ? _mainParser.parseOn(context)
        : Failure<String>(
            context.buffer, context.buffer.length, 'No tag element found');
  }
}
