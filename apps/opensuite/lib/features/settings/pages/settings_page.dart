import 'package:fileutility_core/fileutility_core.dart';
import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_bloc.dart';

/// Settings page providing theme, editor, and general configuration.
class SettingsPage extends StatelessWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.settings),
        centerTitle: false,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const AppLoadingIndicator(message: 'Loading settings...');
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Appearance section
              const _SectionHeader(title: AppLocalizations.appearance),
              _ThemeSelector(currentMode: state.themeMode),
              const Divider(height: AppSpacing.xxxl),

              // Editor section
              const _SectionHeader(title: AppLocalizations.editor),
              _FontSizeSlider(fontSize: state.fontSize),
              SwitchListTile(
                title: const Text(AppLocalizations.lineNumbers),
                subtitle: const Text('Show line numbers in the text editor'),
                value: state.showLineNumbers,
                onChanged: (_) =>
                    context.read<SettingsBloc>().add(const ToggleLineNumbers()),
              ),
              SwitchListTile(
                title: const Text(AppLocalizations.wordWrap),
                subtitle: const Text('Wrap long lines to fit the editor width'),
                value: state.wordWrap,
                onChanged: (_) =>
                    context.read<SettingsBloc>().add(const ToggleWordWrap()),
              ),
              const Divider(height: AppSpacing.xxxl),

              // Autosave section
              const _SectionHeader(title: AppLocalizations.autosave),
              SwitchListTile(
                title: const Text(AppLocalizations.autosave),
                subtitle: const Text('Automatically save changes'),
                value: state.autosaveEnabled,
                onChanged: (_) =>
                    context.read<SettingsBloc>().add(const ToggleAutosave()),
              ),
              if (state.autosaveEnabled)
                _AutosaveIntervalSelector(
                  currentSeconds: state.autosaveIntervalSeconds,
                ),
              const Divider(height: AppSpacing.xxxl),

              // Accessibility section
              const _SectionHeader(title: 'Accessibility'),
              SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text(
                    'WCAG AAA compliant colors with increased contrast ratios'),
                value: state.highContrastMode,
                onChanged: (_) => context
                    .read<SettingsBloc>()
                    .add(const ToggleHighContrast()),
              ),
              ListTile(
                title: const Text(AppLocalizations.language),
                subtitle: Text(SupportedLocales.getDisplayName(
                  Locale(state.localeCode),
                )),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, state.localeCode),
              ),
              const Divider(height: AppSpacing.xxxl),

              // About section
              const _SectionHeader(title: AppLocalizations.about),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                title: const Text(AppLocalizations.appName),
                subtitle: const Text(
                  '${AppLocalizations.version} ${AppConstants.appVersion}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Source Code'),
                subtitle: const Text(AppConstants.repositoryUrl),
                onTap: () {
                  // Would open URL — handled by url_launcher
                },
              ),
              const ListTile(
                leading: Icon(Icons.balance_rounded),
                title: Text('License'),
                subtitle: Text(AppConstants.license),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentCode) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text(AppLocalizations.language),
        children: [
          RadioGroup<String>(
            groupValue: currentCode,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(ChangeLocale(value));
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: SupportedLocales.all.map((locale) {
                final code = locale.languageCode;
                final isSelected = code == currentCode;
                return RadioListTile<String>(
                  title: Text(SupportedLocales.getDisplayName(locale)),
                  subtitle: Text(locale.toString()),
                  value: code,
                  selected: isSelected,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.currentMode});

  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_rounded),
            label: Text('System'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_rounded),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_rounded),
            label: Text('Dark'),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (selection) {
          context.read<SettingsBloc>().add(ChangeThemeMode(selection.first));
        },
      ),
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  const _FontSizeSlider({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${AppLocalizations.fontSize}: ${fontSize.round()}px'),
      subtitle: Slider(
        value: fontSize,
        min: 10,
        max: 24,
        divisions: 14,
        label: '${fontSize.round()}px',
        onChanged: (value) {
          context.read<SettingsBloc>().add(ChangeFontSize(value));
        },
      ),
    );
  }
}

class _AutosaveIntervalSelector extends StatelessWidget {
  const _AutosaveIntervalSelector({required this.currentSeconds});

  final int currentSeconds;

  @override
  Widget build(BuildContext context) {
    final options = [10, 15, 30, 60, 120, 300];

    return ListTile(
      title: const Text(AppLocalizations.autosaveInterval),
      trailing: DropdownButton<int>(
        value: options.contains(currentSeconds) ? currentSeconds : 30,
        items: options.map((seconds) {
          final label = seconds < 60 ? '${seconds}s' : '${seconds ~/ 60}m';
          return DropdownMenuItem(value: seconds, child: Text(label));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.read<SettingsBloc>().add(ChangeAutosaveInterval(value));
          }
        },
      ),
    );
  }
}
