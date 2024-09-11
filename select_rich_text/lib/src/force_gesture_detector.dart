import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'monodrag.dart';

class ForceGestureDetector extends StatefulWidget {
  final Widget? child;

  const ForceGestureDetector({Key? key, @required this.child})
      : super(key: key);

  @override
  _ForceGestureDetectorState createState() => _ForceGestureDetectorState();
}

class _ForceGestureDetectorState extends State<ForceGestureDetector> {
  final Map<Type, GestureRecognizerFactory> gestures =
      <Type, GestureRecognizerFactory>{};
  var data;
  Function(DragDownDetails details) onPanDown = (data) {};

  Function(DragStartDetails details) onPanStart = (data) {};

  Function(DragUpdateDetails details) onPanUpdate = (data) {
  };

  Function(DragEndDetails details) onPanEnd = (data) {};

  Function() onPanCancel = () {};

  @override
  void initState() {
    super.initState();
    gestures[ForcePanGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ForcePanGestureRecognizer>(
      () => ForcePanGestureRecognizer(debugOwner: this),
      (ForcePanGestureRecognizer instance) {
        instance
          ..onDown = onPanDown
          ..onStart = onPanStart
          ..onUpdate = onPanUpdate
          ..onEnd = onPanEnd
          ..onCancel = onPanCancel;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: gestures,
      child: widget.child,
    );
  }
}
