import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:select_rich_text/select_multi_text.dart';
import 'package:select_rich_text/src/force_gesture_detector.dart';
import 'package:select_rich_text/src/select_copy_painter.dart';

class CopyText extends StatefulWidget {
  final Offset pressPosition;
  final Map<int, InlineSpan?> spans;
  final Map<int, Element> spanElements;
  final ValueChanged? onCopyCallBak;

  const CopyText({
    Key? key,
    required this.pressPosition,
    required this.spans,
    required this.spanElements,
    this.onCopyCallBak,
  }) : super(key: key);

  @override
  _CopyTextState createState() => _CopyTextState();
}

class _CopyTextState extends State<CopyText> {
  //每个RichText对应的起点位置范围
  Map<int, TextRange> _firstTextRanges = {};

  //每个RichText对应的起点位置
  Map<int, TextPosition> _firstTextPositions = {};

  //每个RichText对应的终点位置
  Map<int, TextPosition> _maxTextPositions = {};

  //每个RichText对应的实际字符串
  Map<int, String> spanStrings = {};

  //每个RichText对应的需要复制的字符串
  Map<int, String> copyStrings = {};

  //每个RichText对应的绘制区域
  Map<int, List<TextBox>> boxes = {};

  //每个RichText对应的需要过滤的绘制区域
  Map<int, List<TextBox>> placeHolderBoxes = {};

  //第一个widget的key
  GlobalKey _preFirstChildKey = GlobalKey();

  //最后一个widget的key
  GlobalKey _afterLastChildKey = GlobalKey();

  //是否在顶部显示复制布局
  bool _isShowCopyOnTop = true;

  //是否能显示复制布局
  bool _isShowCopyWidget = false;

  static final double kCopyTextWidth = 100;
  static final double kCopyTextHeight = 40;
  static final double kCopyWidgetSize = 28;

  @override
  void initState() {
    super.initState();
    _handleData(widget.pressPosition);
  }

  //处理字符串和获取需要过滤的box
  _handleString(key, renderParagraph) {
    String string = widget.spans[key]?.toPlainText() ?? "";
    List<String> chars = string.characters.toList();
    List<TextBox> placeHolders = [];
    for (int i = 0; i < chars.length; i++) {
      if (chars[i] == "￼") {
        placeHolders.addAll(renderParagraph.getBoxesForSelection(TextSelection(
            baseOffset: i,
            extentOffset: i + 1,
            affinity: TextAffinity.upstream)));
      }
    }
    placeHolderBoxes[key] = placeHolders;
    spanStrings[key] = string;
  }

  //处理起点需要在0的情况
  _handleLeft(key, RenderParagraph renderParagraph) {
    TextPosition position = TextPosition(offset: 0);
    TextRange range = TextRange(start: 0, end: 0);
    TextPosition maxPosition = renderParagraph.getPositionForOffset(
        Offset(renderParagraph.size.width, renderParagraph.size.height));
    _maxTextPositions[key] = maxPosition;
    _firstTextRanges[key] = range;
    _firstTextPositions[key] = position;
    boxes[key] = renderParagraph.getBoxesForSelection(TextSelection(
        baseOffset: range.start,
        extentOffset: range.end,
        affinity: position.affinity));
  }

  //处理起点需要在终点的情况
  _handleRight(key, renderParagraph, offset) {
    offset = Offset(renderParagraph.size.width, offset.dy);
    TextPosition position = renderParagraph.getPositionForOffset(offset);
    TextRange range = renderParagraph.getWordBoundary(position);
    range = TextRange(start: range.end, end: range.end);
    TextPosition maxPosition = renderParagraph.getPositionForOffset(
        Offset(renderParagraph.size.width, renderParagraph.size.height));
    _maxTextPositions[key] = maxPosition;
    _firstTextRanges[key] = range;
    _firstTextPositions[key] = position;
    boxes[key] = renderParagraph.getBoxesForSelection(TextSelection(
        baseOffset: range.start,
        extentOffset: range.end,
        affinity: position.affinity));
  }

  //正常处理
  _handleNormal(key, renderParagraph, offset) {
    TextPosition position = renderParagraph.getPositionForOffset(offset);
    TextRange range = renderParagraph.getWordBoundary(position);
    TextPosition maxPosition = renderParagraph.getPositionForOffset(
        Offset(renderParagraph.size.width, renderParagraph.size.height));
    _maxTextPositions[key] = maxPosition;
    _firstTextRanges[key] =
        TextRange(start: max(0, range.start - 1), end: range.start);
    _firstTextPositions[key] = position;
    var allBoxes = renderParagraph.getBoxesForSelection(TextSelection(
        baseOffset: range.start,
        extentOffset: range.end,
        affinity: position.affinity));
    allBoxes.removeWhere((element) => placeHolderBoxes[key]!.contains(element));
    boxes[key] = allBoxes;
    _isShowCopyOnTop = true;
    _isShowCopyWidget = true;
  }

  //处理数据
  _handleData(Offset startOffset) {
    widget.spanElements.forEach((key, value) {
      RenderParagraph? renderParagraph =
          value.findRenderObject() as RenderParagraph?;
      _handleString(key, renderParagraph);

      ///获取点击位置局部坐标
      Offset offset = startOffset - renderParagraph!.localToGlobal(Offset.zero);
      //左上，点击位置在当前组件左上方
      if (offset.dx < 0 && offset.dy < 0) {
        _handleLeft(key, renderParagraph);
        return;
      }
      //左下，点击位置在当前组件左下方
      if (offset.dx < 0 && offset.dy > renderParagraph.size.height) {
        _handleRight(key, renderParagraph, offset);
        return;
      }
      //右上
      if (offset.dx > renderParagraph.size.width && offset.dy < 0) {
        _handleLeft(key, renderParagraph);
        return;
      }
      //右下
      if (offset.dx > renderParagraph.size.width &&
          offset.dy > renderParagraph.size.height) {
        _handleRight(key, renderParagraph, offset);
        return;
      }
      //上中
      if (offset.dy < 0) {
        _handleLeft(key, renderParagraph);
        return;
      }
      //下中
      if (offset.dy > renderParagraph.size.height) {
        _handleRight(key, renderParagraph, offset);
        return;
      }
      //左中
      if (offset.dx < 0) {}
      //右中
      if (offset.dx > renderParagraph.size.width) {}
      _handleNormal(key, renderParagraph, offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    RenderBox? renderBox = context
        .findAncestorStateOfType<SelectMultiTextState>()!
        .context
        .findRenderObject() as RenderBox?;
    return Stack(
      clipBehavior: Clip.none,
      children: _getChildren(renderBox),
    );
  }

  _getChildren(RenderBox? renderBox) {
    var time=DateTime.now().millisecondsSinceEpoch;
    List<Widget> list = [];
    boxes.forEach((key, value) {
      var widgets = value.map((e) {
        RenderParagraph? renderParagraph =
            widget.spanElements[key]!.findRenderObject() as RenderParagraph?;
        var top = renderParagraph!.localToGlobal(Offset.zero).dy +
            e.top -
            renderBox!.localToGlobal(Offset.zero).dy;
        var left = renderParagraph.localToGlobal(Offset.zero).dx +
            e.left -
            renderBox.localToGlobal(Offset.zero).dx;
        return Positioned(
          top: top,
          left: left,
          height: e.bottom - e.top,
          width: e.right - e.left,
          child: Container(
            color: Colors.blue.withOpacity(0.3),
          ),
        );
      });
      list.addAll(widgets);
    });
    if (list.isNotEmpty) {
      Positioned? firstPositioned = list.first as Positioned?;
      Positioned? lastPositioned = list.last as Positioned?;
      if (firstPositioned != null && lastPositioned != null) {
        var firstWidget = _getFirstWidget(firstPositioned);
        var lastWidget = _getLastWidget(lastPositioned);
        list.add(firstWidget);
        list.add(lastWidget);
        if (_isShowCopyWidget) {
          list.add(getCopyWidget(renderBox, firstPositioned, lastPositioned,
              firstWidget, lastWidget));
        }
      }
    }
    // print("构建ui时间：${DateTime.now().millisecondsSinceEpoch-time}");
    return list;
  }

  _getFirstWidget(Positioned? firstChild) {
    return Positioned(
      top: firstChild!.top! + firstChild.height!,
      left: firstChild.left! - kCopyWidgetSize,
      height: kCopyWidgetSize,
      width: kCopyWidgetSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: ForceGestureDetector(
          key: _preFirstChildKey,
          child: Transform.rotate(
            angle: pi / 2,
            child: CustomPaint(
              painter: CopyPainter(
                color: Colors.blue,
              ),
            ),
          ),
        ),
        onPointerDown: (down) {
          onMoveStart(down, _preFirstChildKey);
        },
        onPointerMove: onMoveEvent,
        onPointerUp: onPointerUp,
      ),
    );
  }

  _getLastWidget(Positioned? lastChild) {
    return Positioned(
      top: lastChild!.top! + lastChild.height!,
      left: lastChild.left! + lastChild.width!,
      height: kCopyWidgetSize,
      width: kCopyWidgetSize,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: ForceGestureDetector(
          key: _afterLastChildKey,
          child: CustomPaint(
            painter: CopyPainter(
              color: Colors.blue,
            ),
          ),
        ),
        onPointerDown: (down) {
          onMoveStart(down, _afterLastChildKey);
        },
        onPointerMove: onMoveEvent,
        onPointerUp: onPointerUp,
      ),
    );
  }

  getCopyWidget(RenderBox? renderBox, Positioned? first, Positioned? last,
      Positioned preFirst, Positioned afterLast) {
    Offset offset =
        _handleCopyWidgetPosition(renderBox, first, last, preFirst, afterLast);
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: Visibility(
        visible: _isShowCopyWidget,
        child: Container(
          width: kCopyTextWidth,
          height: kCopyTextHeight,
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 4.0,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "复制",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  onTap: _handleCopy,
                ),
                InkWell(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "全选",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  onTap: () {
                    _handleSelectAll(renderBox);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _handleCopyWidgetPosition(RenderBox? renderBox, Positioned? first,
      Positioned? last, Positioned preFirst, Positioned afterLast) {
    double left;
    double top;
    var screenWidth = MediaQuery.of(context).size.width;
    if (_isShowCopyOnTop) {
      left = first!.left!;
      top = first.top! - kCopyTextHeight;
      //父布局屏幕坐标
      Offset globalPosition = renderBox!.localToGlobal(Offset(left, top));
      if (top < 0) {
        //顶部距离不够，走下方流程
        top = top + first.height!;
        if (screenWidth - globalPosition.dx < kCopyTextWidth) {
          left = left - kCopyTextWidth;
        }
      } else {
        if (screenWidth - globalPosition.dx < kCopyTextWidth) {
          left = left - kCopyTextWidth;
        }
      }
    } else {
      left = last!.left! + last.width!;
      top = last.top! + last.height! + afterLast.height!;
      Offset globalPosition = renderBox!.localToGlobal(Offset(left, top));
      var currentLocation = renderBox.localToGlobal(Offset(left, top)).dy -
          renderBox.localToGlobal(Offset.zero).dy +
          kCopyTextHeight;
      if (currentLocation > renderBox.size.height) {
        var offset = renderBox.localToGlobal(
            Offset(left + afterLast.width! + kCopyTextWidth, top));
        if (offset.dx < screenWidth) {
          left = left + afterLast.width!;
          top = top - last.height!;
        } else {
          left = left - kCopyTextWidth;
          top = top - last.height!;
        }
      } else {
        if (screenWidth - globalPosition.dx < kCopyTextWidth) {
          left = left - kCopyTextWidth + afterLast.width!;
        }
      }
    }
    return Offset(left, top);
  }

  Offset? _localPressPosition;

  _handleCopy() {
    String copy = copyStrings.values.join("").replaceAll("￼", "");
    // Clipboard.setData(ClipboardData(text: copy));
    if (widget.onCopyCallBak != null) {
      widget.onCopyCallBak!(copy);
    }
    setState(() {
      _isShowCopyWidget = false;
    });
  }

  _handleSelectAll(RenderBox? renderBox) {
    Offset offset = renderBox!.localToGlobal(Offset.zero);
    Offset realPosition = Offset(
        renderBox.size.width + offset.dx, renderBox.size.height + offset.dy);
    _localPressPosition = Offset.zero;
    var screenPoint = Offset(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    var y = -renderBox.globalToLocal(screenPoint).dy;
    Offset lastOffset = Offset(0, y);
    _handleData(lastOffset);
    onMoveEvent(PointerMoveEvent(position: realPosition));
    onPointerUp(null);
  }

  onMoveStart(PointerDownEvent down, key) {
    Offset realPosition = down.position;
    RenderBox renderBox = key.currentContext.findRenderObject();
    _localPressPosition = renderBox.globalToLocal(realPosition);
    if (key == _preFirstChildKey) {
      //点击左图标
      RenderBox? renderBox =
          _afterLastChildKey.currentContext!.findRenderObject() as RenderBox?;
      _handleData(renderBox!.localToGlobal(Offset(-1, -1)));
      _isShowCopyOnTop = true;
    }
    if (key == _afterLastChildKey) {
      //点击右图标
      RenderBox? renderBox =
          _preFirstChildKey.currentContext!.findRenderObject() as RenderBox?;
      //知道widget宽度，需要知道字符长度，得到单位宽度
      _handleData(renderBox!
          .localToGlobal(Offset(max(renderBox.size.width - 1, 0), -1)));
      _isShowCopyOnTop = false;
    }
    _isShowCopyWidget = false;
  }

  onPointerUp(data) {
    _isShowCopyWidget = true;
    setState(() {});
  }

  onMoveEvent(PointerMoveEvent event) {
    //实际位置需要减去点击位置本地距离
    var time=DateTime.now().millisecondsSinceEpoch;
    Offset realPosition = Offset(
        event.position.dx, event.position.dy - _localPressPosition!.dy - 1);
    for (var key in widget.spans.keys) {
      //获取当前位置字符串坐标
      var time=DateTime.now().millisecondsSinceEpoch;
      RenderParagraph? renderParagraph =
          widget.spanElements[key]?.findRenderObject() as RenderParagraph?;
      if (renderParagraph == null) {
        break;
      }
      Offset localPosition = renderParagraph.globalToLocal(realPosition);
      if (realPosition.dy < renderParagraph.localToGlobal(Offset.zero).dy) {
        //从当前Widget跳转到上方widget，全选一行
        localPosition = Offset(0.0, localPosition.dy);
      }
      if (realPosition.dy >
          renderParagraph.localToGlobal(Offset.zero).dy +
              renderParagraph.size.height) {
        //从当前Widget跳转到下方widget，全选一行
        localPosition = Offset(renderParagraph.size.width, localPosition.dy);
      }
      var position = renderParagraph.getPositionForOffset(localPosition);
      var textRange = renderParagraph.getWordBoundary(position);
      var allBoxes = renderParagraph.getBoxesForSelection(TextSelection(
          baseOffset: textRange.start,
          extentOffset: _firstTextRanges[key]!.end,
          affinity: position.affinity));
      allBoxes
          .removeWhere((element) => placeHolderBoxes[key]!.contains(element));
      boxes[key] = allBoxes;
      // print("单次消耗时间：${DateTime.now().millisecondsSinceEpoch-time}");
      if (position.offset == _firstTextPositions[key]!.offset) {
        continue;
      }
      if (position.offset < _firstTextPositions[key]!.offset) {
        copyStrings[key] = spanStrings[key]!.substring(
            position.offset,
            (_firstTextPositions[key]!.offset)
                .clamp(0, _maxTextPositions[key]!.offset));
      } else {
        copyStrings[key] = spanStrings[key]!.substring(
            (_firstTextPositions[key]!.offset)
                .clamp(0, _maxTextPositions[key]!.offset),
            position.offset);
      }
    }
    setState(() {});
    // print("消耗时间：${DateTime.now().millisecondsSinceEpoch-time}");
  }
}
