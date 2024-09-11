import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sys_gravity_sensor/sys_gravity_sensor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void dispose() {
    super.dispose();

    SysGravitySensor.removeGravityOrientationListener(_gravityListener);
    SysGravitySensor.disableGravityWatcher();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> initPlatformState() async {
    String platformVersion;

    try {
      platformVersion = await SysGravitySensor.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              OutlinedButton (
                  onPressed: () {
                    onOpen();
                  },
                  child: Container(width: 80, child: Text('打开设备方向'))),
              OutlinedButton (
                  onPressed: () {
                    onEnableGravityWatcher();
                  },
                  child: Container(width: 80, child: Text('开启设备方向监听'))),
              OutlinedButton (
                  onPressed: () {
                    onDisableGravityWatcher();
                  },
                  child: Container(width: 80, child: Text('关闭设备方向监听'))),
              OutlinedButton (
                  onPressed: () {
                    onLocationPermission();
                  },
                  child: Container(width: 80, child: Text('调取位置权限'))),
              OutlinedButton (
                  onPressed: () {
                    onCameraPermission();
                  },
                  child: Container(width: 80, child: Text('调取相机权限'))),
            ],
          ),
        ),
      ),
    );
  }
  onOpen() async{
    var kkk = await SysGravitySensor.setOpenGravity(isOPenGravity: true);
    print("--$kkk");
  }
  onEnableGravityWatcher() async{
    print("errorListener: onAttachedToEngine------1212----------999");
    SysGravitySensor.enableGravityWatcher();
    SysGravitySensor.addGravityOrientationListener(_gravityListener);
  }

  onDisableGravityWatcher() async{
    SysGravitySensor.removeGravityOrientationListener(_gravityListener);
    SysGravitySensor.disableGravityWatcher();
  }

  onLocationPermission() async{
    var location = await SysGravitySensor.setLocationPermission(packageName: "com.sun.ygxy");
    print("--location-$location");
  }

  onCameraPermission() async{
    var camera = await  SysGravitySensor.setCameraPermission(packageName: "com.sun.ygxy");
    print("--camera-$camera");
  }

  void _gravityListener(){
    print("final===orientation: ${SysGravitySensor.value.orientation}");
  }
}
