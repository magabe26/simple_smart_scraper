import 'package:meta/meta.dart';
/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:petitparser/petitparser.dart';
import 'package:simple_smart_scraper/src/parsers/parser_util_mixin.dart';
import '../../simple_smart_scraper.dart';
import '../element_start_tag.dart';

/// Parses html or xml for opening/start tag specified , with one or more specified attributes.
class ElementStartTagParser extends Parser<ElementStartTag>
    with ParserUtilMixin {
  final Set<String> tags;
  final Set<String> attributes;

  ///True if the opening tag is closed otherwise is false
  final bool isClosed;

  ///The maximum number of results to be returned, specify -1 for limitless
  final int limit;

  ElementStartTagParser({
    @required this.tags,
    @required this.attributes,
    @required this.isClosed,
    @required this.limit,
  })  : assert(tags != null),
        assert(attributes != null),
        assert(isClosed != null),
        assert(limit != null);

  @override
  Parser<ElementStartTag> copy() {
    return ElementStartTagParser(
        tags: tags, attributes: attributes, isClosed: isClosed, limit: limit);
  }

  @override
  Parser<String> flatten([String message]) {
    return ElementStartTagFlattenParser(this, message);
  }

  List<RegExpMatch> _allTagMatches;
  int _matchIndex = 0;
  int _count = 0;

  Map<String, String> _getAttributes(String startTag) {
    var attributes =
        parsers.getParserResults(parser: parsers.attribute(), input: startTag);

    // ignore: omit_local_variable_types
    Map<String, String> map = <String, String>{};
    for (var attr in attributes) {
      attr = attr.trim();
      if (attr.isNotEmpty) {
        final index = attr.indexOf('=', 0);
        if (index >= 0) {
          final key = attr.substring(0, index).trim();
          final value = parsers.removeQuotes(attr.substring(index + 1));
          if (key.isNotEmpty) {
            //value can be empty
            map[key] = value;
          }
        }
      }
    }
    return map;
  }

  bool _hasAtLeastOneQualifiedAttribute(Set<String> startTagAttributes) {
    if (((attributes == null) || (attributes.isEmpty)) &&
        startTagAttributes.isEmpty) {
      return true;
    }

    //make non case sensitive match
    final attrs = attributes.map((attr) => attr.toLowerCase().trim());
    for (var attr in startTagAttributes) {
      if (attrs.contains(attr.toLowerCase().trim())) {
        return true;
      }
    }
    return false;
  }

  @override
  Result<ElementStartTag> parseOn(Context context) {
    final buffer = context.buffer;
    if (context.position < buffer.length) {
      //ONE TIME INIT
      _allTagMatches ??= allTagRegex.allMatches(buffer).toList();

      while (_matchIndex < _allTagMatches.length) {
        // ignore: omit_local_variable_types
        RegExpMatch match = _allTagMatches.elementAt(_matchIndex);
        // ignore: omit_local_variable_types
        String matchStr = buffer.substring(match.start, match.end);
        // ignore: omit_local_variable_types
        bool _isEndTag = isEndTag(matchStr);
        // ignore: omit_local_variable_types
        bool _isStartTag = !_isEndTag;

        _matchIndex++;

        if (_isStartTag) {
          final tag = getTagFromStartTag(matchStr);
          if (tag.isNotEmpty) {
            final startTag = StartTag(
              tag: tag,
              value: matchStr,
              start: match.start,
              end: match.end,
            );
            // ignore: omit_local_variable_types
            final int bufferStart = buffer.indexOf(startTag.value);
            // ignore: omit_local_variable_types
            final int bufferEnd = bufferStart + startTag.value.length;

            final elementStartTag = ElementStartTag(
                tag: tag,
                isClosed: startTag.isClosed,
                markup: startTag.value,
                attributes: _getAttributes(startTag.value));
            // ignore: omit_local_variable_types
            final bool isQualifiedTag = tags.contains(elementStartTag.tag);
            if (isQualifiedTag &&
                _hasAtLeastOneQualifiedAttribute(
                    elementStartTag.attributes.keys.toSet()) &&
                (isClosed == elementStartTag.isClosed)) {
              if (limit == -1) {
                return Success(buffer, bufferEnd, elementStartTag);
              } else {
                _count++;
                if (_count >= limit) {
                  return Success(
                      buffer, buffer.length /*end parsing*/, elementStartTag);
                } else {
                  return Success(buffer, bufferEnd, elementStartTag);
                }
              }
            }
          }
        }
      }

      return Failure<ElementStartTag>(
          buffer, context.position, 'No element found,');
    } else {
      return Failure<ElementStartTag>(
          buffer, buffer.length, 'No element found, position > buffer.length.');
    }
  }
}

class ElementStartTagFlattenParser extends DelegateParser<String> {
  final String message;
  ElementStartTagFlattenParser(ElementStartTagParser delegate, [this.message])
      : super(delegate);

  @override
  Result<String> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Success<ElementStartTag>) {
      return Success<String>(
          result.buffer, result.position, result.value.toString());
    } else {
      if (message == null) {
        return Failure<String>(result.buffer, result.position, '');
      } else {
        return Failure<String>(result.buffer, result.position, message);
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
      other is ElementStartTagFlattenParser &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  ElementStartTagFlattenParser copy() => ElementStartTagFlattenParser(delegate);
}
