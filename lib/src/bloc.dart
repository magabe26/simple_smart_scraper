/**
 * Copyright 2019 - MagabeLab (Tanzania). All Rights Reserved.
 * Author Edwin Magabe    edyma50@yahoo.com
 */

import 'dart:async';

abstract class Bloc<E, S> {
  final StreamController<E> _eventController = StreamController<E>();
  StreamSink<E> _eventsSink;
  Stream<E> _eventStream;

  final StreamController<S> _stateController = StreamController<S>();
  StreamSink<S> _statesSink;
  Stream<S> _stateStream;
  StreamSubscription<E> _eventStreamSubscription;
  StreamSubscription<S> _stateStreamSubscription;

  Bloc() {
    _statesSink = _stateController.sink;
    _stateStream = _stateController.stream;

    _eventsSink = _eventController.sink;
    _eventStream = _eventController.stream;

    _eventStreamSubscription = _eventStream.listen((event) async {
      mapEventToState(event).listen((state) {
        _statesSink.add(state);
      }, onError: (e) {
        _statesSink.addError(e);
      });
    });
  }

  Stream<S> mapEventToState(E event);

  Stream<S> get stream => _stateStream;

  void dispatchEvent(E event) {
    _eventsSink.add(event);
  }

  void dispatchDelayedEvent(Duration duration, E event) {
    Future.delayed(duration, () {
      dispatchEvent(event);
    });
  }

  void listen(
    void Function(S balance) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    _stateStreamSubscription = _stateStream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future<void> dispose() async {
    await _eventStreamSubscription.cancel();

    if (_stateStreamSubscription != null) {
      await _stateStreamSubscription.cancel();
    }
    await _eventController.close();
    await _stateController.close();
  }
}
