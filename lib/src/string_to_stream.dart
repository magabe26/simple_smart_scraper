/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'dart:async';

Stream<String> stringToStream(String str) async* {
  yield str ?? '';
}
