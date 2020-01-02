/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:simple_smart_scraper/src/element.dart';
import 'package:simple_smart_scraper/petitparser_2.4.0.dart';
import 'any_element_parser_base.dart';

/// Parse any tag elements,comments and empty  elements, except text, provided exceptionalTags
class AnyElementParser extends AnyElementParserBase {
  @override
  final Set<String> exceptionalTags;

  @override
  AnyElementParser(this.exceptionalTags);

  @override
  Parser<String> copy() {
    return AnyElementParser(exceptionalTags);
  }

  @override
  String onTransformElement(Element element) {
    return element.toString();
  }
}
