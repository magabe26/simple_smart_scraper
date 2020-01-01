/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:xml/xml.dart';

class NonCaseSensitiveXmlElementsFinder {
  static Iterable<XmlElement> findAllElements(
    XmlParent xmlParent,
    String name,
  ) {
    if ((xmlParent == null) || (name == null) || name.isEmpty) {
      return <XmlElement>[];
    }
    // ignore: omit_local_variable_types
    Iterable<XmlElement> elements = xmlParent.findAllElements(name);
    if ((elements == null) || elements.isEmpty) {
      elements = xmlParent.findAllElements(name.toLowerCase());
    }

    if ((elements == null) || elements.isEmpty) {
      elements = xmlParent.findAllElements(name.toUpperCase());
    }

    return elements ?? <XmlElement>[];
  }
}
