import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum SYSDeviceType {
  PortraitUp,

  /// 竖直屏幕
  LandscapeLeft,

  /// 手机左转
  PortraitDown,

  /// 竖直反转屏幕
  LandscapeRight,

  /// 手机右转
  FaceUp,

  /// 手机屏幕朝上
  FaceDown,

  /// 手机屏幕朝下
  Unknown,

  /// 未知
}

class GravityOrientation {
  SYSDeviceType orientation;

//  final int type;

  GravityOrientation({
    required this.orientation,
  }) : assert(orientation != null);

//  @override
//  bool operator ==(Object other) =>
//      identical(this, other) ||
//          (other is GravityOrientation && hashCode == other.hashCode);
//
//  @override
//  int get hashCode => hashValues(orientation, "");
}

class _GravityValueNotifier extends ValueNotifier<GravityOrientation> {
  _GravityValueNotifier(GravityOrientation orientation) : super(orientation);
}

class SysGravitySensor {
  static SYSDeviceType tempOrientation = SYSDeviceType.Unknown;
  static const MethodChannel _channel =
      const MethodChannel('com.gzygxy.method.sys_gravity_sensor');

  static _GravityValueNotifier _notifier = _GravityValueNotifier(
      GravityOrientation(orientation: SYSDeviceType.PortraitUp));

  static StreamSubscription? _eventSubs;

  // 事件通道
  static void enableGravityWatcher() async {
    if (_eventSubs == null) {
      print("errorListener: onAttachedToEngine------1212----------1000");
      await _channel.invokeMethod("enable_gravity_watch");
      _eventSubs = EventChannel("com.gzygxy.event.sys_gravity_sensor")
          .receiveBroadcastStream()
          .listen(_eventListener, onError: _errorListener);
      print("====33===");
    }
  }

  static void disableGravityWatcher() async {
    _eventSubs?.cancel();
    await _channel.invokeMethod("disable_gravity_watch");
    _eventSubs = null;
  }

  static void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    debugPrint("--: $map");
    switch (map['event']) {
      case 'watch':
        {
          String orientation = map['orientation'];
          print("listener_orientation: $orientation");
          switch (orientation) {
            case "orientationPortrait":
              tempOrientation = SYSDeviceType.PortraitUp;
              break;
            case "orientationLandscapeLeft":
              tempOrientation = SYSDeviceType.LandscapeLeft;
              break;
            case "orientationPortraitUpsideDown":
              tempOrientation = SYSDeviceType.PortraitDown;
              break;
            case "orientationLandscapeRight":
              tempOrientation = SYSDeviceType.LandscapeRight;
              break;
            case "orientationFaceUp":
              tempOrientation = SYSDeviceType.FaceUp;
              break;
            case "orientationFaceDown":
              tempOrientation = SYSDeviceType.FaceDown;
              break;
            case "orientationUnknown":
              tempOrientation = SYSDeviceType.Unknown;
              break;
            default:
              tempOrientation = SYSDeviceType.Unknown;
              break;
          }
          _notifier.value = GravityOrientation(orientation: tempOrientation);
        }
        break;
      default:
        break;
    }
    print("tempOrientation:$tempOrientation");
  }

  static _handleResult(final orientation) {
    Future.delayed(Duration(milliseconds: 1500), () {
      if (orientation == tempOrientation) {
        _notifier.value = GravityOrientation(orientation: tempOrientation);
      }
    });
  }

  static void _errorListener(Object obj) {
    print("errorListener: $obj");
  }

  static void addGravityOrientationListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  static void removeGravityOrientationListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  // 方法通道
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> setOpenGravity({bool isOPenGravity = true}) async {
    var _isGravityOpen =
        await _channel.invokeMethod("setOpenGravity", <String, dynamic>{
      'isOPenGravity': isOPenGravity,
    });
    return _isGravityOpen;
  }

  static Future<bool> setPhotoPermission({String? packageName}) async {
    var _permission =
        await _channel.invokeMethod("setPhotoPermission", <String, dynamic>{
      'packageName': packageName,
    });
    return _permission;
  }

  static Future<bool> setCameraPermission({String? packageName}) async {
    var _permission =
        await _channel.invokeMethod("setCameraPermission", <String, dynamic>{
      'packageName': packageName,
    });
    return _permission;
  }

  static Future<bool> setLocationPermission({String? packageName}) async {
    var _permission =
        await _channel.invokeMethod("setLocationPermission", <String, dynamic>{
      'packageName': packageName,
    });
    return _permission;
  }

  static GravityOrientation get value => _notifier.value;
}
