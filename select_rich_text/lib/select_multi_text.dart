import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:select_rich_text/src/copy_text_widget.dart';

class SelectMultiTextWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged? onCopyCallBak;

  const SelectMultiTextWidget(
      {Key? key, required this.child, this.onCopyCallBak})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SelectMultiTextState();
  }
}

class SelectMultiTextState extends State<SelectMultiTextWidget> {
  Map<int, InlineSpan?> spans = {};
  Map<int, Element> spanElements = {};
  Size? _parentSize;
  Offset _pressLocalPosition = Offset.zero;
  bool showCopyWidget = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      getTree(context);
    });
  }

  getTree(BuildContext context) {
    context.visitChildElements((element) {
      if (element.widget.runtimeType == Text) {
        Text? text = element.widget as Text?;
        if (text?.data != null) {
          spans[element.hashCode] = TextSpan(text: text?.data);
        } else {
          spans[element.hashCode] = text?.textSpan;
        }
        spanElements[element.hashCode] = element;
      }
      getTree(element);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        children: [
          GestureDetector(
            child: widget.child,
            onLongPressEnd: _onLongPressEnd,
          ),
          Visibility(
            visible: showCopyWidget,
            child: Container(
              width: _parentSize?.width ?? 0,
              height: _parentSize?.height ?? 0,
              child: CopyText(
                pressPosition: _pressLocalPosition,
                spans: spans,
                spanElements: spanElements,
                onCopyCallBak: _onCopySuccess,
              ),
            ),
          )
        ],
      ),
      onTap: () {
        setState(() {
          showCopyWidget = false;
        });
      },
    );
  }

  _onLongPressEnd(LongPressEndDetails event) {
    _pressLocalPosition = event.globalPosition;
    _parentSize = context.size;
    setState(() {
      showCopyWidget = true;
    });
  }

  _onCopySuccess(value) {
    setState(() {
      showCopyWidget = false;
    });
    widget.onCopyCallBak!(value);
  }
}
