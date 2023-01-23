import 'dart:async';

class MyStream {
  final _controller = StreamController<String>();

  Stream<String> get stream => _controller.stream;

  void addString(String value) {
    _controller.sink.add(value);
  }

  void dispose() {
    _controller.close();
  }
}
