import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'di/app_module.dart';

/// Application entry point.
///
/// Initializes core services and launches the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  final config = AppConfig.production();
  EnvironmentConfig.initialize(config);

  // Initialize dependency injection
  await setupServiceLocator(config: config);
  await AppModule.initialize();

  runApp(const OpenSuiteApp());
}
