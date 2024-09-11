import 'package:flutter/material.dart';
import 'package:select_rich_text/select_multi_text.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var response;

  @override
  void initState() {
    getHttp();
    super.initState();
  }

  void getHttp() async {
    // try {
    //   response = await Dio().get('https://pub.flutter-io.cn/packages/dio');
    //   print(response);
    //   setState(() {});
    // } catch (e) {
    //   print(e);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        // body: SingleChildScrollView(
        //   child: response != null
        //       ? SelectMultiTextWidget(
        //           child: Html(data: "${response?.data}"),
        //         )
        //       : Container(),
        // ),
      ),
    );
  }
}
