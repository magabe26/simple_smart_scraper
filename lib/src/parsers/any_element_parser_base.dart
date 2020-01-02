/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:simple_smart_scraper/src/element.dart';
import 'package:simple_smart_scraper/src/parsers/parser_util_mixin.dart';
import 'package:simple_smart_scraper/src/parsers/simple_flatten_parser.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';

import '../../simple_smart_scraper.dart';

/// Parse any tag elements,comments and empty  elements, except text, provided exceptionalTags
/// A base class implement onTransformElement method and transform the parsed element
abstract class AnyElementParserBase extends Parser<String>
    with ParserUtilMixin {
  Set<String> get exceptionalTags => <String>{};

  @override
  Parser<String> copy();

  @override
  Parser<String> flatten([String message]) {
    return SimpleFlattenParser(this, message);
  }

  TagMap<StartTag> _startTagMap;
  List<RegExpMatch> _allTagMatches;
  int _matchIndex = 0;

  String onTransformElement(Element element);

  @override
  Result<String> parseOn(Context context) {
    final buffer = context.buffer;
    if (context.position < buffer.length) {
      //ONE TIME INIT
      if ((_allTagMatches == null) && (_startTagMap == null)) {
        _startTagMap = TagMap<StartTag>();
        _allTagMatches = allTagRegex.allMatches(buffer).toList();
      }

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

            if (startTag.isClosed) {
              //onElementFound , closeEndElement eg. <link ref=""  />
              if (!exceptionalTags.contains(startTag.tag)) {
                final element = Element(
                    type: ElementType.closeEndElement,
                    tag: startTag.tag,
                    markup: startTag.value);
                final transformed = onTransformElement(element);
                if (transformed != null) {
                  return Success<String>(buffer, bufferEnd, transformed);
                }
              }
            } else {
              //onElementFound ,meta or br
              if (startTag.isMeta || startTag.isBr) {
                if (!exceptionalTags.contains(startTag.tag)) {
                  final element = Element(
                      type: ElementType.openEndElement,
                      tag: startTag.tag,
                      markup: startTag.value);
                  final transformed = onTransformElement(element);
                  if (transformed != null) {
                    return Success<String>(buffer, bufferEnd, transformed);
                  }
                }
              } else {
                //not reached the end,until we reach the end tag
                _startTagMap.add(startTag); //push to stack
              }
            }
          } else {
            //onElementFound , commentElement
            if (isComment(matchStr)) {
              final commentElement = matchStr;
              // ignore: omit_local_variable_types
              final int bufferStart = buffer.indexOf(commentElement);
              // ignore: omit_local_variable_types
              final int bufferEnd = bufferStart + commentElement.length;

              if ((!exceptionalTags.contains('comment')) &&
                  (!exceptionalTags.contains('comments'))) {
                var element =
                    Element(type: ElementType.comment, markup: matchStr);

                final transformed = onTransformElement(element);
                if (transformed != null) {
                  return Success<String>(buffer, bufferEnd, transformed);
                }
              }
            } else {
              //the string may be other element
              /* element =
                  Element(type: ElementType.otherElement, markup: matchStr);*/
            }
          }
        } else {
          //means it is EndTag

          final tag = matchStr
              .replaceAll('<', '')
              .replaceAll('/', '')
              .replaceAll('>', '')
              .trim();

          if (_startTagMap.contains(tag)) {
            // ignore: omit_local_variable_types
            StartTag startTag = _startTagMap.get(tag);
            // ignore: omit_local_variable_types
            final int elementStartIndex = startTag.start;
            // ignore: omit_local_variable_types
            final int elementEndIndex = match.end;

            final completeOpenEndElement =
                buffer.substring(elementStartIndex, elementEndIndex);
            // ignore: omit_local_variable_types
            final int bufferStart = buffer.indexOf(completeOpenEndElement);
            // ignore: omit_local_variable_types
            final int bufferEnd = bufferStart + completeOpenEndElement.length;

            //onElementFound , openEndElement
            if (!exceptionalTags.contains(startTag.tag)) {
              final element = Element(
                  type: ElementType.openEndElement,
                  tag: tag,
                  markup: completeOpenEndElement);
              final transformed = onTransformElement(element);
              if (transformed != null) {
                return Success<String>(buffer, bufferEnd, transformed);
              }
            }
          }
        }
      }

      return Failure<String>(buffer, context.position, 'No element found,');
    } else {
      return Failure<String>(
          buffer, buffer.length, 'No element found, position > buffer.length.');
    }
  }
}
