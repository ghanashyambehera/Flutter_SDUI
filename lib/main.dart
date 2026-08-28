import 'package:flutter/material.dart';
import 'package:flutter_sdui/app.dart';
import 'package:flutter_sdui/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SduiApp());
}
