import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';

import 'features/settings/bloc/settings_bloc.dart';
import 'router/app_router.dart';
import 'di/app_module.dart';

/// Root application widget.
///
/// Configures theming, routing, and provides global BLoC instances.
class OpenSuiteApp extends StatelessWidget {
  /// Creates the [OpenSuiteApp].
  const OpenSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => AppModule.settingsBloc..add(const LoadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'OpenSuite',
            debugShowCheckedModeBanner: false,

            // Theme — switches between standard and high contrast
            theme: settingsState.highContrastMode
                ? AppTheme.highContrastLight
                : AppTheme.light,
            darkTheme: settingsState.highContrastMode
                ? AppTheme.highContrastDark
                : AppTheme.dark,
            themeMode: settingsState.themeMode,

            // Routing
            routerConfig: AppRouter.router,

            // Localization
            locale: Locale(settingsState.localeCode),
            supportedLocales: SupportedLocales.all,
          );
        },
      ),
    );
  }
}
