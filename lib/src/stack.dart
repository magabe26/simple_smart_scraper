/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */
import 'dart:core';

class Stack<T> {
  final List<T> _memory = <T>[];

  void push(T value) => _memory.add(value);

  T pop() => (_memory.isNotEmpty) ? _memory.removeAt(0) : null;

  int get length => _memory.length;

  bool get isEmpty => _memory.isEmpty;

  bool get isNotEmpty => _memory.isNotEmpty;

  bool contains(T element) => _memory.contains(element);

  T pickLast() => _memory.isNotEmpty ? _memory.last : null;

  T pickAt(int index) =>
      ((index > 0) && (index < length)) ? _memory.elementAt(index) : null;

  @override
  String toString() {
    return '$_memory';
  }
}
