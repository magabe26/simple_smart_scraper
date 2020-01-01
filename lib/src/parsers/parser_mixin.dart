/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */
import 'dart:async';
import 'dart:convert';
import 'package:petitparser/petitparser.dart';
import 'package:meta/meta.dart';
import 'package:simple_smart_scraper/src/parsers/any_element_parser.dart';
import 'package:simple_smart_scraper/src/parsers/any_word_parser.dart';
import 'package:simple_smart_scraper/src/parsers/attribute_parser.dart';
import 'package:simple_smart_scraper/src/parsers/children_elements_parser.dart';
import 'package:simple_smart_scraper/src/parsers/element_text_parser.dart';
import 'package:simple_smart_scraper/src/parsers/forward_parser.dart';
import 'package:simple_smart_scraper/src/parsers/intercepted_parser.dart';
import '../../simple_smart_scraper.dart';
import 'parsers.dart';

const String _otherPermittedAttributeValueChars =
    '-+\$:;.,/?&=%#_@\\\u00B7\u0300-\u036F\u203F-\u2040\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF'
    '\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001'
    '\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD';

typedef Finalizer = Future<String> Function(String output);
typedef FinalizerSync = String Function(String output);

///Any parser that wishes to parse any formatted string(xml ,html etc) must mix with this mixin
mixin ParserMixin {
  Parser start() => char('<');

  Parser end() => char('>');

  Parser slash() => char('/');

  Parser spaceOptional() => whitespace().star();

  Parser quote() => char('"') | char("'");

  Parser equal() => char('=');

  Parser repeat(Parser p, int times) => repeatRange(p, min: times, max: times);

  Parser anyWord({@required Set<String> except, bool caseSensitive = true}) =>
      AnyWordParser(except: except, caseSensitive: caseSensitive);

  Parser repeatRange(
    Parser p, {
    @required int min,
    @required int max,
  }) =>
      spaceOptional().seq(p).seq(spaceOptional()).repeat(min, max);

  /// In the following examples
  ///    final str = '''
  ///          chura CHURA ChurA ChUrA mkia is awesome
  ///       ''';
  ///
  /// nonCaseSensitiveChars("chura").flatten().matchesSkipping(str);
  /// returns [chura CHURA ChurA ChUrA]
  Parser nonCaseSensitiveChars(String str) {
    if ((str == null) || str.isEmpty) {
      return undefined('argument "str" can not be empty or null');
    }
    Parser p;
    str.split('').forEach((c) {
      final parser = pattern('${c.toLowerCase()}${c.toUpperCase()}');
      if (p == null) {
        p = parser;
      } else {
        p = p.seq(parser);
      }
    });
    return p;
  }

  Parser attributeValue() {
    final any = (letter() |
            digit() |
            whitespace() |
            pattern(_otherPermittedAttributeValueChars))
        .star();

    final singleWordValue = word().plus(); /*key=value*/

    final anyValue =
        (quote().seq(any).seq(quote())); /*key='value' or key="value*/

    final emptyValue =
        (quote().seq(spaceOptional()).seq(quote())); /*key='' or key="*/

    return (emptyValue | singleWordValue | anyValue).plus();
  }

  Parser attributeKey([String key]) => (key == null)
      ? letter().plus().seq((letter() | digit() | pattern('-_~.')).star())
      : nonCaseSensitiveChars(key);

  Parser attribute([
    String key,
    bool hasValue = true,
  ]) =>
      AttributeParser(key, hasValue: hasValue, caseSensitive: false);

  /// In the following examples
  ///    final str = '''
  ///          <tag attr1 ="attribute1"> Text </tag>
  ///          <TAG> TEXT </TAG>
  ///            <tag/>
  ///       ''';
  ///  elementStartTag(tag:'tag'); matches both  <tag attr1 ="attribute1"> and  <TAG>
  ///     while
  ///  elementStartTag(tag:'tag',isClosed: true); matches only <tag/>
  ///  specify maxNoOfAttributes < 0 or null  for no attributes
  Parser elementStartTag({
    String tag,
    int maxNoOfAttributes = 6,
    bool isClosed = false,
  }) {
    // ignore: omit_local_variable_types
    final Parser attr = (maxNoOfAttributes <= 0 || (maxNoOfAttributes == null))
        ? spaceOptional()
        : spaceOptional().seq(attribute().star()).repeat(1, maxNoOfAttributes);

    Parser p = start()
        .seq((tag == null) ? word().plus() : nonCaseSensitiveChars(tag))
        .seq(spaceOptional())
        .seq(attr)
        .seq(spaceOptional());

    if (isClosed) {
      p = p.seq(slash());
    }

    p = p.seq(end());

    return p;
  }

  Parser elementEndTag([String tag]) => start()
      .seq(slash())
      .seq((tag == null) ? word().plus() : nonCaseSensitiveChars(tag))
      .seq(end());

  /// In the following examples
  ///    final str = '''
  ///          <tag attr1 ="attribute1"> Text </tag>
  ///          <TAG> TEXT </TAG>
  ///       ''';
  ///  element('tag'); matches both  <tag attr1 ="attribute1"> Text </tag>
  ///  and  <TAG> TEXT </TAG>
  Parser element(
    String tag, {
    Parser startTag,
    Parser endTag,
  }) {
    return spaceOptional().seq(
        ((startTag != null) ? startTag : elementStartTag(tag: tag))
            .seq(spaceOptional())
            .seq(spaceOptional()
                .seq(any()
                    .starLazy((endTag != null) ? endTag : elementEndTag(tag))
                    .flatten('element: Expected any text'))
                .pick(1)
                .optional(''))
            .seq(spaceOptional())
            .seq((endTag != null) ? endTag : elementEndTag(tag)));
  }

  ///Parse element with no attributes and text
  Parser emptyElement(String tag) {
    final closed =
        elementStartTag(tag: tag, maxNoOfAttributes: 0, isClosed: true);
    final complete = elementStartTag(tag: tag, maxNoOfAttributes: 0)
        .seq(spaceOptional())
        .seq(elementEndTag(tag));

    final br = start()
        .seq(spaceOptional())
        .seq(nonCaseSensitiveChars('br'))
        .seq(spaceOptional())
        .seq(end());
    return spaceOptional().seq(closed.or(complete).or(br));
  }

  /// Match any children elements except text and provided exception
  Parser childrenElements({Set<String> except = const <String>{}}) =>
      ChildrenElementsParser(except);

  /// Match  any element except text and provided exception,
  /// also see [getElements]
  Parser anyElement({Set<String> except = const <String>{}}) =>
      AnyElementParser(except);

  /// In the following examples
  ///    final str = '''
  ///        <tr>  <tag attr1 ="attribute1"> Text </tag> </tr>
  ///          <TAG> TEXT </TAG>
  ///       ''';
  ///  parentElement("tr",element('tag'));
  ///  matches  <tr>  <tag attr1 ="attribute1"> Text </tag> </tr>
  Parser parentElement(
    String tag,
    Parser element, {
    Parser startTag,
    Parser endTag,
  }) {
    return spaceOptional().seq(
        ((startTag != null) ? startTag : elementStartTag(tag: tag))
            .seq(spaceOptional())
            .seq(element)
            .seq(spaceOptional())
            .seq((endTag != null) ? endTag : elementEndTag(tag)));
  }

  Parser parentElementWithNoAttributes(String tag) {
    return spaceOptional()
        .seq(elementStartTag(tag: tag, maxNoOfAttributes: 0))
        .seq(spaceOptional())
        .seq(spaceOptional()
            .seq(any()
                .starLazy(elementEndTag(tag))
                .flatten('element: Expected any text'))
            .pick(1)
            .optional(''))
        .seq(spaceOptional())
        .seq(elementEndTag(tag));
  }

  ///Parse and return a text of an element
  Parser elementText(String tag) => ElementTextParser(tag);

  ///Prefer using this method instead of a corresponding parser
  String getElementText({
    @required String tag,
    @required String input,
  }) {
    if ((tag == null) || (tag.isEmpty) || (input == null) || (input.isEmpty)) {
      return '';
    }
    return getParserResult(parser: elementText(tag), input: input);
  }

  ///Return the first successful parser result as a string
  String getParserResult({
    @required Parser parser,
    @required String input,
  }) {
    if ((parser == null) || (input == null) || (input.isEmpty)) {
      return '';
    }

    var results = getParserResults(parser: parser, input: input);
    return results.isNotEmpty ? results.elementAt(0) : '';
  }

  ///Return all successful parser results
  List<String> getParserResults({
    @required Parser parser,
    @required String input,
  }) {
    return (parser == null)
        ? <String>[]
        : parser.flatten().matchesSkipping(input);
  }

  /// Example : _qualifiedElement('a');  parses
  ///  <a href="link">  , <a href="link"></a> and  <a href="link"/> successfully
  Parser qualifiedElement(String tag) => element(tag)
      .or(elementStartTag(tag: tag, isClosed: true))
      .or(elementStartTag(tag: tag));

  String getAttributeValue({
    @required String tag,
    @required String attribute,
    @required String input,
  }) {
    if ((tag == null) ||
        tag.isEmpty ||
        (attribute == null) ||
        attribute.isEmpty ||
        (input == null) ||
        input.isEmpty) {
      return '';
    }

    // ignore: omit_local_variable_types
    final String element =
        getParserResult(parser: qualifiedElement(tag), input: input);

    // ignore: omit_local_variable_types
    final String startTag = getParserResult(
        parser: elementStartTag(tag: tag)
            .or(elementStartTag(tag: tag, isClosed: true)),
        input: element);
    // ignore: omit_local_variable_types
    String attributeStr =
        getParserResult(parser: this.attribute(attribute), input: startTag);
    if (attributeStr.isNotEmpty) {
      // ignore: omit_local_variable_types
      final int index = attributeStr.indexOf('=', 0);
      if (index != -1) {
        var attr = attributeStr.substring(index + 1).trim();
        if (attr.isNotEmpty) {
          return removeQuotes(attr);
        } else {
          return attr;
        }
      }
    }
    return '';
  }

  bool beginAndEndWithTest(int quoteCode, String input) {
    return ((quoteCode == input[0].codeUnitAt(0)) &&
        (quoteCode == input[input.length - 1].codeUnitAt(0)));
  }

  bool beginAndEndWithDoubleQuote(String input) {
    return beginAndEndWithTest('"'.codeUnitAt(0), input);
  }

  bool beginAndEndWithSingleQuote(String input) {
    return beginAndEndWithTest("'".codeUnitAt(0), input);
  }

  String removeQuotes(String input) {
    if (beginAndEndWithSingleQuote(input) ||
        beginAndEndWithDoubleQuote(input)) {
      //remove the last quote
      var lastRemoved = input.replaceRange(input.length - 1, input.length, '');
      return lastRemoved.substring(1).trim(); //the remove the first quote
    } else {
      return input.trim();
    }
  }

  Set<String> getElementTags(String input) {
    return SimpleSmartParser.parse(input).allTags;
  }

  Map<String, String> getElementAttributes({
    @required Parser parser,
    @required String input,
  }) {
    var attributes = getParserResults(
        parser: attribute(),
        input: getParserResult(
            //Only use start tag of parent element to avoid child-parent attribute mixing in the final results
            parser: elementStartTag().or(elementStartTag(isClosed: true)),
            input: getParserResult(
              parser: parser,
              input: input,
            )));

    // ignore: omit_local_variable_types
    Map<String, String> map = <String, String>{};
    for (var attr in attributes) {
      attr = attr.trim();
      if (attr.isNotEmpty) {
        final index = attr.indexOf('=', 0);
        if (index >= 0) {
          final key = attr.substring(0, index).trim();
          final value = removeQuotes(attr.substring(index + 1));
          if (key.isNotEmpty) {
            //value can be empty
            map[key] = value;
          }
        }
      }
    }
    return map;
  }

  bool hasAttribute({
    @required String tag,
    @required String attribute,
    @required String input,
  }) {
    return getAttributeValue(
      tag: tag,
      attribute: attribute,
      input: input,
    ).isNotEmpty;
  }

  ///1. If both tag and attributes are NOT NULL and NOT EMPTY, then attributes specified will be removed from the tag
  ///2. If the tag is NULL or EMPTY and attributes is NOT NULL and NOT EMPTY, then attributes specified will be removed from all tags
  ///3. if  the tag is NOT NULL and NOT EMPTY and attribute is NULL or EMPTY , then if the tag specified has attributes, they will all be removed
  ///4. If both tag and attributes are NULL or EMPTY , then all attributes of all tags will be removed
  String removeAttributes({
    String tag,
    Set<String> attributes,
    @required String input,
  }) {
    var output = input;
    final tags =
        ((tag != null) && tag.isNotEmpty) ? [tag] : [...getElementTags(input)];

    //Collecting all elements first
    var allElements = [];
    for (var currentTag in tags) {
      final list =
          getParserResults(parser: qualifiedElement(currentTag), input: input);

      allElements.addAll(list);
    }

    sortLargerItemsFirst(allElements);

    //Replacement , using a map to record changes
    // ignore: omit_local_variable_types
    Map<String, String> beforeAndAfterMap = <String, String>{};

    for (var currentTag in tags) {
      for (var elem in allElements) {
        final previous = elem;
        final currentTagAttributes = getElementAttributes(
                parser: qualifiedElement(currentTag), input: elem)
            .keys;

        final attributesToRemove =
            ((attributes != null) && attributes.isNotEmpty)
                ? attributes
                : {...currentTagAttributes};

        for (var attrToRemove in attributesToRemove) {
          final attrFoundList =
              getParserResults(parser: attribute(attrToRemove), input: elem);

          for (var attr in attrFoundList) {
            elem = elem.replaceAll(attr, '');
            beforeAndAfterMap[previous] = elem;
          }
        }
      }
    }

    //Finally replace string, start with larger one(that may contain smaller),
    // to avoid element mismatch during replacement
    final beforeElements = beforeAndAfterMap.keys;
    for (var before in beforeElements) {
      output = output.replaceAll(before, beforeAndAfterMap[before]);
    }
    return output;
  }

  void sortLargerItemsFirst(List<dynamic> input) {
    input?.sort((a, b) => b.compareTo(a));
  }

  void sortSmallerItemsFirst(List<dynamic> input) {
    input?.sort((a, b) => a.compareTo(b));
  }

  /// The String form is  key="Value"
  Map<String, String> getElementAttributesStrings({
    @required String input,
  }) {
    var attributes = getParserResults(
        parser: attribute(),
        input: getParserResult(
            //only use start tag of parent element to avoid child-parent attribute mixing in the final results
            parser: elementStartTag().or(elementStartTag(isClosed: true)),
            input: input));

    // ignore: omit_local_variable_types
    Map<String, String> map = <String, String>{};
    for (var attr in attributes) {
      attr = attr.trim();
      if (attr.isNotEmpty) {
        final index = attr.indexOf('=', 0);
        if (index >= 0) {
          final key = attr.substring(0, index).trim();
          if (key.isNotEmpty) {
            map[key] = attr;
          }
        }
      }
    }
    return map;
  }

  ///if the tag is NOT NULL and NOT EMPTY, then the operation is performed only on that tag ,otherwise the operation is performed on all tags of the input
  ///Specifying NULL or EMPTY attributes means remove all attributes,
  ///if the element becomes empty after all attributes are removed (ie <a></a> ), an empty string is returned
  ///The results tends to be better as filterLoop increase up to a reasonable number
  ///You can pass more than one tag as an array of string to the 'tag' parameter as a string ie. ['link','div'].toString();
  Future<String> keepAttributes({
    String tag,
    @required Set<String> attributes,
    @required String input,
    int filterLoop = 2,
    Finalizer finalizer,
  }) {
    attributes ??= <String>{};

    if (filterLoop > 6) {
      filterLoop = 6;
    }

    if (filterLoop < 0) {
      filterLoop = 2;
    }

    List<String> getTags() {
      if ((tag != null) && tag.isNotEmpty) {
        return [...getElementTags(input)];
      }
      List<String> _t;
      try {
        _t = jsonDecode(tag) as List<String>;
        if (_t is! List) {
          _t = [tag];
        }
      } catch (_) {
        _t = [tag];
      }
      return _t.isNotEmpty ? _t : [...getElementTags(input)];
    }

    var output = input;

    final tags = getTags();

    // ignore: omit_local_variable_types
    Completer<String> completer = Completer<String>();

    void runFilter(Function cb) {
      Future.delayed(Duration(milliseconds: 80), () {
        // ignore: omit_local_variable_types
        int loop = 0;
        while (loop < filterLoop) {
          cb();
          loop++;
        }

        // ignore: omit_local_variable_types
        List<Parser> emptyElements =
            tags.map((tag) => emptyElement(tag)).toList();

        //remove empty elements
        // ignore: omit_local_variable_types
        int removeLoop = 0;
        while (removeLoop < (filterLoop + 1)) {
          output = remove(parsers: emptyElements, input: output);
          removeLoop++;
        }

        if (finalizer != null) {
          completer.complete(finalizer(output));
        } else {
          completer.complete(output);
        }
      });
    }

    runFilter(() {
      for (var currentTag in tags) {
        var elementList = getParserResults(
            parser: qualifiedElement(currentTag), input: output);

        // ignore: omit_local_variable_types
        int currentElement = 0;
        while (currentElement < elementList.length) {
          var elem = elementList.elementAt(currentElement);

          // ignore: omit_local_variable_types
          final int elementStartPositionInTheOutput = output.indexOf(elem);
          // final elementEndPositionInTheOutput = elementStartPositionInTheOutput + elem.length;

          final currentTagAttributes = getElementAttributes(
                  parser: qualifiedElement(currentTag), input: elem)
              .keys;
          final attributesToRemove = currentTagAttributes.where(
              (attributeToKeep) => !attributes.contains(attributeToKeep));
          for (var attrToRemove in attributesToRemove) {
            final attrFoundList =
                getParserResults(parser: attribute(attrToRemove), input: elem);

            for (var attr in attrFoundList) {
              // ignore: omit_local_variable_types
              final int attrStartIndex =
                  output.indexOf(attr, elementStartPositionInTheOutput);
              if (attrStartIndex != -1) {
                // ignore: omit_local_variable_types
                final int attrEndIndex = attrStartIndex + attr.length;
                //remove attribute and update output
                output = output.replaceRange(attrStartIndex, attrEndIndex, '');
              }
            }
          }

          //reload list with the current state/output
          elementList = getParserResults(
              parser: qualifiedElement(currentTag), input: output);

          currentElement++;
        }
      }
    });

    return completer.future;
  }

  ///Sync Version
  ///if the tag is NOT NULL and NOT EMPTY, then the operation is performed only on that tag ,otherwise the operation is performed on all tags of the input
  ///Specifying NULL or EMPTY attributes means remove all attributes
  ///The results tends to be better as filterLoop increase up to a reasonable number
  ///You can pass more than one tag as an array of string to the 'tag' parameter as a string ie. ['link','div'].toString();
  String keepAttributesSync({
    String tag,
    @required Set<String> attributes,
    @required String input,
    int filterLoop = 2,
    FinalizerSync finalizer,
  }) {
    attributes ??= <String>{};

    if (filterLoop > 6) {
      filterLoop = 6;
    }

    if (filterLoop < 0) {
      filterLoop = 2;
    }

    List<String> getTags() {
      if ((tag != null) && tag.isNotEmpty) {
        return [...getElementTags(input)];
      }
      List<String> _t;
      try {
        _t = jsonDecode(tag) as List<String>;
        if (_t is! List) {
          _t = [tag];
        }
      } catch (_) {
        _t = [tag];
      }
      return _t.isNotEmpty ? _t : [...getElementTags(input)];
    }

    var output = input;

    final tags = getTags();

    String runFilter(Function cb) {
      // ignore: omit_local_variable_types
      int loop = 0;
      while (loop < filterLoop) {
        cb();
        loop++;
      }

      // ignore: omit_local_variable_types
      List<Parser> emptyElements =
          tags.map((tag) => emptyElement(tag)).toList();

      //remove empty elements
      // ignore: omit_local_variable_types
      int removeLoop = 0;
      while (removeLoop < (filterLoop + 1)) {
        output = remove(parsers: emptyElements, input: output);
        removeLoop++;
      }

      if (finalizer != null) {
        return finalizer(output);
      } else {
        return output;
      }
    }

    return runFilter(() {
      for (var currentTag in tags) {
        var elementList = getParserResults(
            parser: qualifiedElement(currentTag), input: output);

        // ignore: omit_local_variable_types
        int currentElement = 0;
        while (currentElement < elementList.length) {
          var elem = elementList.elementAt(currentElement);

          // ignore: omit_local_variable_types
          final int elementStartPositionInTheOutput = output.indexOf(elem);
          // final elementEndPositionInTheOutput = elementStartPositionInTheOutput + elem.length;

          final currentTagAttributes = getElementAttributes(
                  parser: qualifiedElement(currentTag), input: elem)
              .keys;
          final attributesToRemove = currentTagAttributes.where(
              (attributeToKeep) => !attributes.contains(attributeToKeep));

          for (var attrToRemove in attributesToRemove) {
            final attrFoundList =
                getParserResults(parser: attribute(attrToRemove), input: elem);
            for (var attr in attrFoundList) {
              // ignore: omit_local_variable_types
              final int attrStartIndex =
                  output.indexOf(attr, elementStartPositionInTheOutput);
              if (attrStartIndex != -1) {
                // ignore: omit_local_variable_types
                final int attrEndIndex = attrStartIndex + attr.length;
                //remove attribute and update output
                output = output.replaceRange(attrStartIndex, attrEndIndex, '');
              }
            }
          }

          //reload list with the current state/output
          elementList = getParserResults(
              parser: qualifiedElement(currentTag), input: output);

          currentElement++;
        }
      }
    });
  }

  String remove({
    @required List<Parser> parsers,
    @required String input,
  }) {
    if (((parsers == null) || parsers.isEmpty) ||
        ((input == null) || input.isEmpty)) {
      return input;
    }
    // ignore: omit_local_variable_types
    String output = input;

    for (var parser in parsers) {
      var lst = getParserResults(parser: parser, input: input);
      for (var result in lst) {
        output = output.replaceAll(result, '');
      }
    }
    return output.trim();
  }

  int getParserResultCount({
    @required Parser parser,
    @required String input,
  }) {
    return getParserResults(parser: parser, input: input).length;
  }

  int getElementOpenStartTagCount(String input) {
    return getParserResultCount(parser: elementStartTag(), input: input);
  }

  int getElementEndTagCount(String input) {
    return getParserResultCount(parser: elementEndTag(), input: input);
  }

  bool verifyInput(String input) {
    if (getElementOpenStartTagCount(input) == getElementEndTagCount(input)) {
      final startTags = getParserResults(
        parser: elementStartTag(),
        input: input,
      ).map((s) => getTagFromElementStartTag(s));

      final endTags = getParserResults(
        parser: elementEndTag(),
        input: input,
      ).map((s) => getTagFromElementEndTag(s));
      for (var i = 0; i < startTags.length; i++) {
        if (!endTags.contains(startTags.elementAt(i))) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  String getTagFromElementStartTag(String input) {
    return getParserResult(
            parser: start()
                .seq(spaceOptional())
                .seq(letter().seq((letter() | digit()).star()))
                .seq(spaceOptional()),
            input: input)
        .replaceAll('<', '')
        .trim();
  }

  String getTagFromElementEndTag(String input) {
    return getParserResult(
            parser: start()
                .seq(spaceOptional())
                .seq(slash())
                .seq(spaceOptional())
                .seq(letter().seq((letter() | digit()).star()))
                .seq(spaceOptional())
                .seq(end()),
            input: input)
        .replaceAll('<', '')
        .replaceAll('/', '')
        .replaceAll('>', '')
        .trim();
  }

  ///Remove the parentElement and returns its children/content which could be other element(s) or text
  String strip(String input) {
    if (input == null || input.isEmpty) {
      throw StripException('Unexpected error occured', '');
    }
    input = input.trim();

    if (!verifyInput(input)) {
      throw StripException(
          '>>>>>\n***Error: parser error , invalid input formart **** <<<<<',
          input);
    }

    var closed = elementStartTag(maxNoOfAttributes: 0, isClosed: true)
        .or(elementStartTag(isClosed: true));
    var closedElements = getParserResults(parser: closed, input: input);
    for (var closedElem in closedElements) {
      // ignore: omit_local_variable_types
      final int index = input.indexOf(closedElem);
      // ignore: omit_local_variable_types
      final bool startedWithClosedElement = (index == 0);
      //strip failed
      if (startedWithClosedElement) {
        throw StripException(
            '>>>>>\n***Error:No one root parent element found, the first element is the closed element **** <<<<<',
            input);
      }
    }

    final startTag =
        elementStartTag(maxNoOfAttributes: 0).or(elementStartTag());

    var startElements = getParserResults(parser: startTag, input: input);
    for (var startElem in startElements) {
      if (input.indexOf(startElem) == 0) {
        final tag = getTagFromElementStartTag(startElem);
        final endTags =
            getParserResults(parser: elementEndTag(tag), input: input);
        // ignore: omit_local_variable_types
        int tagLastIndex = -1;
        // ignore: omit_local_variable_types
        int tagLen = 0;
        // ignore: omit_local_variable_types
        String endTag = '';
        for (var end in endTags) {
          // ignore: omit_local_variable_types
          int i = input.indexOf(end, tagLastIndex + 1);
          if (i > tagLastIndex) {
            tagLastIndex = i;
            tagLen = end.length;
            endTag = end;
          }
        }

        final elements = getParserResults(parser: element(tag), input: input);
        String firstElement;
        for (var e in elements) {
          if (input.indexOf(e) == 0) {
            firstElement = e;
            break;
          }
        }

        if (firstElement != null) {
          // ignore: omit_local_variable_types
          final bool isFirstElementParent =
              (((tagLastIndex + tagLen) == input.length) &&
                  (firstElement.length == input.length));

          // ignore: omit_local_variable_types
          final bool isFirstElementSibling =
              (((tagLastIndex + tagLen) < input.length) &&
                  (firstElement.length == (tagLastIndex + tagLen)));

          if (isFirstElementParent) {
            var striped =
                input.replaceAll(startElem, '').replaceAll(endTag, '').trim();

            return striped;
          }

          if (isFirstElementSibling) {
            throw StripException(
                '>>>>>\n***Error: Can not strip, The element*** \n\n$firstElement  \n\n\t***is not parent but sibling with*** \n\n${input.substring(firstElement.length)}\n\n<<<<<',
                input);
          }
        } else {
          throw StripException(
              '>>>>>\n***Error: parser error , invalid input formart **** <<<<<',
              input);
        }
      } else {
        throw StripException(
            '>>>>>\n***Error: No one root parent element found, siblings element found **** <<<<<',
            input);
      }
    }

    throw StripException('Unexpected error occured', input);
  }

  String stripRepeat(String input, int times) {
    if (!verifyInput(input)) {
      throw StripException(
          '>>>>>\n***Error: parser error , invalid input formart **** <<<<<',
          input);
    }
    if (times < 0) {
      times = 1;
    }

    if (times > 12) {
      times = 12;
    }
    for (var i = 0; i < times; i++) {
      input = strip(input);
    }
    return input;
  }

  Parser meta() => elementStartTag(tag: 'meta')
      .or(elementStartTag(tag: 'meta', isClosed: true));

  bool isMetaTag(String input) => meta().accept(input);

  Parser link() => elementStartTag(tag: 'link')
      .or(elementStartTag(tag: 'link', isClosed: true));

  bool isLinkTag(String input) => link().accept(input);

  Parser script() => elementStartTag(tag: 'script')
      .or(elementStartTag(tag: 'script', isClosed: true))
      .or(element('script'));

  bool isScriptTag(String input) => script().accept(input);

  ///Uses the strip method behind the scenes, therefore it only remove the tags and attributes any texts will be left behind
  ///To remove the entire element , use remove
  Future<String> removeTags({
    @required Set<String> tags,
    @required String input,
    Finalizer finalizer,
  }) async {
    if (((tags == null) || tags.isEmpty) ||
        ((input == null) || input.isEmpty)) {
      return (input != null)
          ? ((finalizer != null) ? finalizer(input.trim()) : input.trim())
          : ((finalizer != null) ? finalizer('') : '');
    }

    // ignore: omit_local_variable_types
    Completer<String> completer = Completer<String>();

    // ignore: omit_local_variable_types
    String output = input;
    var keepTags =
        [...getElementTags(input)].where((tag) => !tags.contains(tag)).toList();

    Future<String> finalize() async {
      output = await removeEmptyTags(output, keepTags: keepTags);
      if (finalizer != null) {
        return finalizer(output);
      } else {
        return output;
      }
    }

    Future.delayed(Duration(milliseconds: 80), () async {
      for (var currentTag in tags) {
        var elemList = getParserResults(
            parser: qualifiedElement(currentTag), input: output);

        if (elemList.isEmpty) {
          continue;
        }

        var currentElemIndex = 0;
        void update() {
          elemList = getParserResults(
              parser: qualifiedElement(currentTag), input: output);
          currentElemIndex = 0;
        }

        while (currentElemIndex < elemList.length) {
          var currentElem = elemList.elementAt(currentElemIndex);
          // ignore: omit_local_variable_types
          final int start = output.indexOf(currentElem);
          // ignore: omit_local_variable_types
          final int end = start + currentElem.length;
          var striped;
          try {
            striped = strip(currentElem);
          } on StripException catch (_) {
            // ignore: omit_local_variable_types
            final bool isClosed =
                elementStartTag(isClosed: true).accept(currentElem);
            if (isClosed) {
              output = output.replaceRange(start, end, '');
              update();
            } else {
              if (isMetaTag(currentElem) || isLinkTag(currentElem)) {
                output = output.replaceRange(start, end, '');
                update();
              } else {
                currentElemIndex++;
              }
            }
            continue;
          }

          if (currentElem != striped) {
            output = output.replaceRange(start, end, striped);
          }
          update();
        }
      }

      output = await finalize();
      completer.complete(output);
    });

    return completer.future;
  }

  ///Sync version of removeTags
  ///Uses the strip method behind the scenes, therefore it only remove the tags and attributes any texts will be left behind
  ///To remove the entire element , use remove
  String removeTagsSync({
    @required Set<String> tags,
    @required String input,
    FinalizerSync finalizer,
  }) {
    if (((tags == null) || tags.isEmpty) ||
        ((input == null) || input.isEmpty)) {
      return (input != null)
          ? ((finalizer != null) ? finalizer(input.trim()) : input.trim())
          : ((finalizer != null) ? finalizer('') : '');
    }

    // ignore: omit_local_variable_types
    String output = input;
    var keepTags =
        [...getElementTags(input)].where((tag) => !tags.contains(tag)).toList();

    String finalize() {
      output = _removeEmptyTagsImpl(output, keepTags: keepTags);
      if (finalizer != null) {
        return finalizer(output);
      } else {
        return output;
      }
    }

    for (var currentTag in tags) {
      var elemList =
          getParserResults(parser: qualifiedElement(currentTag), input: output);

      if (elemList.isEmpty) {
        continue;
      }

      var currentElemIndex = 0;
      void update() {
        elemList = getParserResults(
            parser: qualifiedElement(currentTag), input: output);
        currentElemIndex = 0;
      }

      while (currentElemIndex < elemList.length) {
        var currentElem = elemList.elementAt(currentElemIndex);
        // ignore: omit_local_variable_types
        final int start = output.indexOf(currentElem);
        // ignore: omit_local_variable_types
        final int end = start + currentElem.length;
        var striped;
        try {
          striped = strip(currentElem);
        } on StripException catch (_) {
          // ignore: omit_local_variable_types
          final bool isClosed =
              elementStartTag(isClosed: true).accept(currentElem);
          if (isClosed) {
            output = output.replaceRange(start, end, '');
            update();
          } else {
            if (isMetaTag(currentElem) || isLinkTag(currentElem)) {
              output = output.replaceRange(start, end, '');
              update();
            } else {
              currentElemIndex++;
            }
          }
          continue;
        }

        if (currentElem != striped) {
          output = output.replaceRange(start, end, striped);
        }
        update();
      }
    }

    return finalize();
  }

  ///Uses the strip method behind the scenes, therefore it only remove the tags and attributes any texts will be left behind
  ///To remove the entire element , use remove
  Future<String> keepTags({
    @required Set<String> tags,
    @required String input,
    Finalizer finalizer,
  }) async {
    if (((input == null) || input.isEmpty)) {
      return (input != null)
          ? ((finalizer != null) ? finalizer(input.trim()) : input.trim())
          : ((finalizer != null) ? finalizer('') : '');
    }

    tags ??= <String>{};

    // ignore: omit_local_variable_types
    Set<String> tagsToRemove =
        [...getElementTags(input)].where((tag) => !tags.contains(tag)).toSet();

    return removeTags(tags: tagsToRemove, input: input, finalizer: finalizer);
  }

  String keepTagsSync({
    @required Set<String> tags,
    @required String input,
    FinalizerSync finalizer,
  }) {
    if (((input == null) || input.isEmpty)) {
      return (input != null)
          ? ((finalizer != null) ? finalizer(input.trim()) : input.trim())
          : ((finalizer != null) ? finalizer('') : '');
    }

    tags ??= <String>{};

    // ignore: omit_local_variable_types
    Set<String> tagsToRemove =
        [...getElementTags(input)].where((tag) => !tags.contains(tag)).toSet();

    return removeTagsSync(
        tags: tagsToRemove, input: input, finalizer: finalizer);
  }

  /// Return a [ForwardParser]  that does'nt parse its input ,
  /// but only return the input as the result of the parse operation
  Parser forward() => ForwardParser();

  ///Return an [InterceptedParser] that allow the parsing process to be intercepted by the [Interceptor]
  Parser intercepted({Interceptor interceptor}) =>
      InterceptedParser(interceptor);

  String _cleanImpl({
    @required Set<String> keepTags,
    @required Set<String> keepAttributes,
    @required String input,
  }) {
    keepTags ??= <String>{};

    //Deal with attributes first
    input = keepAttributesSync(
        tag: (keepTags != null) ? keepTags.toList().toString() : null,
        attributes: keepAttributes,
        input: input,
        finalizer: (output) {
          return keepTagsSync(tags: keepTags, input: output);
        });

    // ignore: omit_local_variable_types
    Set<String> unQualifiedElements =
        getElementTags(input).where((tag) => (!keepTags.contains(tag))).toSet();

    return getElements(input: input, except: {
      'comments', //also the _cleanImpl does'nt want comments );
      ...unQualifiedElements
    });
  }

  List<String> filterOutRepeatedElements(List<String> elements) {
    // ignore: omit_local_variable_types
    Map<String, bool> qualificationMap = <String, bool>{};
    elements.forEach((str) {
      qualificationMap[str] = false;
    });

    sortLargerItemsFirst(elements);
    // ignore: omit_local_variable_types
    String checkBuffer = '';
    //filter out repeated
    for (var qualifiedElement in elements) {
      if (!checkBuffer.contains(qualifiedElement)) {
        checkBuffer = '$checkBuffer\n${qualifiedElement.trim()}';
        qualificationMap[qualifiedElement] = true;
      }
    }
    qualificationMap.removeWhere((element, isQualified) {
      return (!isQualified);
    });
    return qualificationMap.keys.toList();
  }

  ///Return a String contain any elements not included in except set
  /// the function uses [AnyElementParser] which parses input and return overlapping/repeated elements
  String getElements({
    Set<String> except = const <String>{},
    @required String input,
  }) {
    return filterOutRepeatedElements(getParserResults(
      parser: anyElement(
          except: except), //also the _cleanImpl does'nt want comments
      input: input,
    )).join('\n');
  }

  ///Easy to use method for cleaning the Html or Xml input
  ///Returns the output with selected tag(  keepTag ) and attribute ( keepAttributes )
  ///Uses strip method behind the scene ,this cause only tags to be remove and their text (if any) to remain.
  ///To remove the entire element(tags ,attributes and text) use [remove] method
  ///              eg;-  remove(parsers:[element('i'],input:input};  ,removes the i tag/element
  String cleanSync({
    @required Set<String> keepTags,
    Set<String> keepAttributes,
    @required String input,
    FinalizerSync finalizer,
  }) {
    keepTags ??= <String>{};

    var output = _cleanImpl(
      keepTags: keepTags,
      keepAttributes: keepAttributes,
      input: input,
    );
    return (finalizer != null) ? finalizer(output) : output;
  }

  ///Async version of cleanSync
  Future<String> clean({
    @required Set<String> keepTags,
    Set<String> keepAttributes,
    @required String input,
    Finalizer finalizer,
  }) async {
    keepTags ??= <String>{};

    var output = _cleanImpl(
      keepTags: keepTags,
      keepAttributes: keepAttributes,
      input: input,
    );

    return (finalizer != null) ? finalizer(output) : output;
  }

  Parser htmlComment() => spaceOptional()
      .seq(start())
      .seq(char('!'))
      .seq(char('-'))
      .seq(char('-'))
      .seq(any().starLazy(char('-').seq(char('-').seq(end()))))
      .seq(char('-').seq(char('-')).seq(end()));

  String removeComments(String input) {
    if (input == null || input.isEmpty) {
      return '';
    }

    return remove(parsers: [htmlComment()], input: input);
  }

  String _removeEmptyTagsImpl(String input, {List<String> keepTags}) {
    // ignore: omit_local_variable_types
    String output = input;

    bool shouldKeep(Match match) {
      if (match.groupCount >= 1) {
        var tag = match[0]
            .replaceAll('<', '')
            .replaceAll('>', '')
            .replaceAll('\\', '')
            .replaceAll('/', '')
            .trim();

        return keepTags.contains(tag) ||
            keepTags.contains(tag.toLowerCase()) ||
            keepTags.contains(tag.toUpperCase());
      } else {
        return false;
      }
    }

    void removeStartWithEmptyTag() {
      output = output.replaceAllMapped(
          RegExp(r'(<\w+\s+>)', caseSensitive: false), (Match m) {
        return shouldKeep(m) ? m[0] : '';
      });
    }

    void removeStartWithNoEmptyTag() {
      output = output.replaceAllMapped(RegExp(r'(<\w+>)', caseSensitive: false),
          (Match m) {
        return shouldKeep(m) ? m[0] : '';
      });
    }

    void removeEndTag() {
      output = output.replaceAllMapped(
          RegExp(r'(</\w+>)', caseSensitive: false), (Match m) {
        return shouldKeep(m) ? m[0] : '';
      });
    }

    removeStartWithEmptyTag();
    removeStartWithNoEmptyTag();
    removeEndTag();

    return output;
  }
}
