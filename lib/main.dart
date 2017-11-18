import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

//Thanks to => https://www.reddit.com/r/dartlang/comments/69luui/minimal_flutter_game_loop/
main() async {
  var deviceTransform = new Float64List(16)
    ..[0] = 1.0 // window.devicePixelRatio
    ..[5] = 1.0 // window.devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;

  var previous = Duration.ZERO;

  // https://github.com/flutter/flutter/issues/5259
  // "In release mode we start off at 0x0 but we don't in debug mode"
  var initialSize = await new Future<Size>(() {
    if (window.physicalSize.isEmpty) {
      var completer = new Completer<Size>();
      window.onMetricsChanged = () {
        if (!window.physicalSize.isEmpty) {
          completer.complete(window.physicalSize);
        }
      };
      return completer.future;
    }
    return window.physicalSize;
  });

  var world = new World(initialSize.width / 2, initialSize.height / 2);

  window.onBeginFrame = (now) {
    var recorder = new PictureRecorder();
    var canvas = new Canvas(
        recorder,
        new Rect.fromLTWH(
            0.0, 0.0, window.physicalSize.width, window.physicalSize.height));

    Duration delta = now - previous;
    if (previous == Duration.ZERO) {
      delta = Duration.ZERO;
    }
    previous = now;

    var t = delta.inMicroseconds / Duration.MICROSECONDS_PER_SECOND;
    world.update(t);
    world.render(t, canvas);

    var builder = new SceneBuilder()
      ..pushTransform(deviceTransform)
      ..addPicture(Offset.zero, recorder.endRecording())
      ..pop();

    window.render(builder.build());
    window.scheduleFrame();
  };

  window.scheduleFrame();

  window.onPointerDataPacket = (packet) {
    var pointer = packet.data.first;
    world.input(pointer.physicalX, pointer.physicalY);
  };
}

class World {
  var _turn = 0.0;
  double _x;
  double _y;

  World(this._x, this._y);

  void input(double x, double y) {
    _x = x;
    _y = y;
  }

  void update(double t) {
    var rotationsPerSecond = 0.25;
    _turn += t * rotationsPerSecond;
  }

  void render(double t, Canvas canvas) {
    var tau = math.PI * 2;

    canvas.drawPaint(new Paint()..color = const Color(0xffFFCC00));
    canvas.save();
    canvas.translate(_x, _y);
    canvas.rotate(tau * _turn);
    var white = new Paint()..color = new Color(0xffffffff);
    var size = 200.0;
    canvas.drawRect(new Rect.fromLTWH(-size / 2, -size / 2, size, size), white);
    canvas.restore();
  }
}
