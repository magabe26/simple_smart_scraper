/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'dart:core';

///Provides common functions that any parser may need
mixin ParserUtilMixin {
  bool isComment(String element) {
    return RegExp(r'(<!--.*-->)').hasMatch(element);
  }

  String getTagFromStartTag(String input) {
    var tagStr = RegExp(r'(<[\w]*\d*)').stringMatch(input);
    if (tagStr != null) {
      return tagStr.replaceAll('<', '').trim();
    } else {
      return '';
    }
  }

  final allTagRegex = RegExp(r'(<[^<>]*>)');

  final endRegex = RegExp(r'(</[^<>]*>)');

  bool isEndTag(String input) => endRegex.hasMatch(input);
}
