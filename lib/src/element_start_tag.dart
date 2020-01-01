/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:meta/meta.dart';

/// A class that represents html or xml opening/start tag
/// e.g;- <a> , <link rel="stylesheet" type="text/css" />  or <br>
class ElementStartTag {
  final String tag;
  final String markup;
  final Map<String, String> attributes;
  final bool isClosed;

  ElementStartTag({
    @required this.tag,
    @required this.isClosed,
    @required this.markup,
    @required this.attributes,
  });

  bool get hasAttributes =>
      (attributes == null) ? false : attributes.isNotEmpty;

  @override
  String toString() {
    return markup;
  }
}
