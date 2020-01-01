/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:meta/meta.dart';
import 'package:simple_smart_scraper/src/element.dart';
import '../stack.dart';

class SimpleSmartParserResult {
  final Map<String, List<Element>> _elements = <String, List<Element>>{};
  final String _comment = 'comment';
  final String _otherElement = 'otherElement';
  final Set<String> _tags = <String>{};

  Set<String> get allTags => _tags;

  void addElement(Element element) {
    if (element.type == ElementType.comment) {
      if (!_elements.containsKey(_comment)) {
        _elements[_comment] = <Element>[];
      }
      _elements[_comment].add(element);
    } else if (element.type == ElementType.otherElement) {
      if (!_elements.containsKey(_otherElement)) {
        _elements[_otherElement] = <Element>[];
      }
      _elements[_otherElement].add(element);
    } else {
      var tag = element.tag;
      if (tag != null && (tag.isNotEmpty)) {
        tag = tag.toLowerCase().trim();
        if (!_elements.containsKey(tag)) {
          _elements[tag] = <Element>[];
        }
        _elements[tag].add(element);
        if (!_tags.contains(tag)) {
          _tags.add(tag);
        }
      }
    }
  }

  Element getElementAt({@required String tag, @required int index}) {
    if ((tag == null) || (tag.isEmpty) || (index < 0)) {
      return null;
    }
    tag = tag.toLowerCase().trim();
    if (!_elements.containsKey(tag)) {
      return null;
    }
    final list = _elements[tag];
    if (list.isNotEmpty) {
      if (index < list.length) {
        return list.elementAt(index);
      }
    }
    return null;
  }

  List<Element> getElements(String tag) {
    if ((tag == null) || (tag.isEmpty)) {
      return null;
    }
    if (!_elements.containsKey(tag)) {
      return null;
    }
    tag = tag.toLowerCase().trim();
    return _elements[tag];
  }

  Element getCommentAt(int index) {
    if ((index < 0)) {
      return null;
    }
    if (!_elements.containsKey(_comment)) {
      return null;
    }
    final list = _elements[_comment];
    if (list.isNotEmpty) {
      if (index < list.length) {
        return list.elementAt(index);
      }
    }
    return null;
  }

  List<Element> getComments() {
    if (!_elements.containsKey(_comment)) {
      return null;
    }
    return _elements[_comment];
  }

  Element getOtherElementAt(int index) {
    if ((index < 0)) {
      return null;
    }
    if (!_elements.containsKey(_otherElement)) {
      return null;
    }
    final list = _elements[_otherElement];
    if (list.isNotEmpty) {
      if (index < list.length) {
        return list.elementAt(index);
      }
    }
    return null;
  }

  List<Element> getOtherElements() {
    if (!_elements.containsKey(_otherElement)) {
      return null;
    }
    return _elements[_otherElement];
  }
}

class SimpleSmartParser {
  ///Parses an html or xml string and return [SimpleSmartParserResult]
  static SimpleSmartParserResult parse(String input) {
    if ((input == null) || (input.isEmpty)) {
      return SimpleSmartParserResult();
    }

    bool isComment(String element) {
      return RegExp(r'(<!--.*-->)').hasMatch(element);
    }

    // ignore: omit_local_variable_types
    SimpleSmartParserResult result = SimpleSmartParserResult();
    // ignore: omit_local_variable_types
    int position = 0;
    // ignore: omit_local_variable_types
    int length = input.length;
    final allTagRegex = RegExp(r'(<[^<>]*>)');
    final endRegex = RegExp(r'(</[^<>]*>)');
    // ignore: omit_local_variable_types
    TagMap<StartTag> startTagMap = TagMap<StartTag>();

    bool isEndTag(String input) => endRegex.hasMatch(input);

    String getTagFromStartTag(String input) {
      var tagStr = RegExp(r'(<[\w]*\d*)').stringMatch(input);
      if (tagStr != null) {
        return tagStr.replaceAll('<', '').trim();
      } else {
        return '';
      }
    }

    void addToResult(Element element) {
      result.addElement(element);
    }

    // ignore: omit_local_variable_types
    final List<RegExpMatch> allMatches = allTagRegex.allMatches(input).toList();
    // ignore: omit_local_variable_types
    int matchIndex = 0;
    while ((position < length) && (matchIndex < allMatches.length)) {
      // ignore: omit_local_variable_types
      RegExpMatch match = allMatches.elementAt(matchIndex);
      // ignore: omit_local_variable_types
      String matchStr = input.substring(match.start, match.end);
      // ignore: omit_local_variable_types
      bool _isEndTag = isEndTag(matchStr);
      // ignore: omit_local_variable_types
      bool _isStartTag = !_isEndTag;
      if (_isStartTag) {
        final tag = getTagFromStartTag(matchStr);
        if (tag.isNotEmpty) {
          final startTag = StartTag(
            tag: tag,
            value: matchStr,
            start: match.start,
            end: match.end,
          );

          if (startTag.isClosed) {
            final element = Element(
                type: ElementType.closeEndElement,
                tag: startTag.tag,
                markup: startTag.value);
            addToResult(element);
          } else {
            if (startTag.isMeta) {
              final element = Element(
                  type: ElementType.openEndElement,
                  tag: startTag.tag,
                  markup: startTag.value);
              addToResult(element);
            } else {
              //wait until we reach the end tag
              startTagMap.add(startTag);
            }
          }
        } else {
          var element;
          if (isComment(matchStr)) {
            //the string may be other element eg; a comment
            element = Element(type: ElementType.comment, markup: matchStr);
          } else {
            element = Element(type: ElementType.otherElement, markup: matchStr);
          }
          addToResult(element);
        }
      } else {
        //isEndTag
        final tag = matchStr
            .replaceAll('<', '')
            .replaceAll('/', '')
            .replaceAll('>', '')
            .trim();
        if (startTagMap.contains(tag)) {
          // ignore: omit_local_variable_types
          StartTag startTag = startTagMap.get(tag);
          // ignore: omit_local_variable_types
          final int elementStartIndex = startTag.start;
          // ignore: omit_local_variable_types
          final int elementEndIndex = match.end;

          final element = Element(
              type: ElementType.openEndElement,
              tag: tag,
              markup: input.substring(elementStartIndex, elementEndIndex));

          //replace complete element
          addToResult(element);
        }
      }
      position = match.end;
      matchIndex++;
    }

    //finally unknown elements
    startTagMap.stillInTheStacks().forEach((startTag) {
      final element = Element(
          type: ElementType.otherElement,
          tag: startTag.tag,
          markup: startTag.value);
      addToResult(element);
    });

    return result;
  }
}

abstract class Tag {
  final String tag;
  final String value;
  final int start;
  final int end;
  bool get isStartTag => false;
  bool get isEndTag => false;

  bool get isClosed => (value != null) ? RegExp(r'/>').hasMatch(value) : false;

  bool get isMeta => tag.toLowerCase().trim() == 'meta';

  bool get isBr => tag.toLowerCase().trim() == 'br';

  Tag({
    @required this.tag,
    @required this.value,
    @required this.start,
    @required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          tag == other.tag &&
          value == other.value &&
          start == other.start &&
          end == other.end &&
          isStartTag == other.isStartTag &&
          isEndTag == other.isEndTag;

  @override
  int get hashCode =>
      value.hashCode ^ start.hashCode ^ end.hashCode ^ tag.hashCode;

  @override
  String toString() {
    return value;
  }
}

class EndTag extends Tag {
  EndTag({
    @required String tag,
    @required String value,
    @required int start,
    @required int end,
  }) : super(tag: tag, value: value, start: start, end: end);

  @override
  bool get isEndTag => true;
}

class StartTag extends Tag {
  StartTag({
    @required String tag,
    @required String value,
    @required int start,
    @required int end,
  }) : super(tag: tag, value: value, start: start, end: end);

  @override
  bool get isStartTag => true;
}

class TagMap<T extends Tag> {
  final Map<String, Stack<T>> _map = <String, Stack<T>>{};
  Stack<T> _getStack(String tag) => _map[tag];

  void _removeEmptyStacks() {
    _map.removeWhere((String tsg, Stack<T> stack) {
      return stack.isEmpty;
    });
  }

  List<Stack<T>> _getActiveStacks() {
    _removeEmptyStacks();
    return _map.values.toList();
  }

  List<T> stillInTheStacks() {
    // ignore: omit_local_variable_types
    List<T> list = [];
    final stacks = _getActiveStacks();
    for (var stack in stacks) {
      while (stack.isNotEmpty) {
        list.add(stack.pop());
      }
    }
    return list;
  }

  T get(String tag) {
    final stack = _getStack(tag);
    return (stack != null) ? stack.pop() : null;
  }

  bool contains(String tag) {
    final stack = _getStack(tag);
    return (stack != null) ? stack.isNotEmpty : false;
  }

  void add(T value) {
    if (value != null) {
      var tag = value.tag;
      if (tag.isNotEmpty) {
        final stack = _getStack(tag);
        if (stack == null) {
          _map[tag] = Stack<T>();
        }
        _map[tag]?.push(value);
      }
    }
  }

  @override
  String toString() {
    _removeEmptyStacks();
    return '$_map';
  }
}
