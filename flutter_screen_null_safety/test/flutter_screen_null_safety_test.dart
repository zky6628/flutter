import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen/flutter_screen_null_safety.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_screen_null_safety');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
