import 'package:flutter/material.dart';

import './core/config/environment_config.dart';
import 'main.dart' as app_main;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(Environment.stage);
  app_main.main();
}
