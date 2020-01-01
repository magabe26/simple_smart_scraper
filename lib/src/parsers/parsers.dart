/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

export 'any_element_parser.dart';
export 'any_word_parser.dart';
export 'attribute_parser.dart';
export 'children_elements_parser.dart';
export 'element_text_parser.dart';
export 'forward_parser.dart';
export 'intercepted_parser.dart';
export 'simple_flatten_parser.dart';
export 'simple_smart_parser.dart';
export 'parser_mixin.dart';

import 'package:simple_smart_scraper/simple_smart_scraper.dart';

class StripException implements Exception {
  final String message;
  final String output;
  StripException(this.message, this.output);

  @override
  String toString() {
    return 'StripException: {message: $message ,\n output: $output} ';
  }
}

class _Parsers with ParserMixin {}

final parsers = _Parsers();
