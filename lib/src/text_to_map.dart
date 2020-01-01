/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'package:meta/meta.dart';

Map<String, String> convertToMap(String text,
    {@required Pattern first, @required Pattern second}) {
  // ignore: omit_local_variable_types
  Map<String, String> map = <String, String>{};
  if ((text != null) && (text.isNotEmpty)) {
    var list = text.trim().split(first);
    for (var v in list) {
      var l = v.split(second);
      if (l.length >= 2) {
        map[l[0].trim()] = l[1].trim();
      }
    }
    return map;
  } else {
    return map;
  }
}
