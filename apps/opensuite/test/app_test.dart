import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/app.dart';
import 'package:opensuite/di/app_module.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Initialize configuration
    final config = AppConfig.development();
    EnvironmentConfig.initialize(config);

    // Initialize dependency injection
    await setupServiceLocator(config: config);
    await AppModule.initialize();

    // Pump the main app widget
    await tester.pumpWidget(const OpenSuiteApp());

    // Wait for settings to load
    await tester.pumpAndSettle();

    // Verify app compiles and builds successfully
    expect(find.byType(OpenSuiteApp), findsOneWidget);
  });
}
