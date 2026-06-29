import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/locale_preferences.dart';
import '../../main.dart';
import '../../db/repositories/store_repository.dart';
import '../../models/store.dart';
import 'about_us.dart';
import 'security_page.dart';
import '../store/store_details_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storeRepo = StoreRepository();
  Store? _store;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _store = await _storeRepo.getById('default_store');
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appState = MyApp.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _sectionHeader(t.translate('store_details'), colors),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.store_rounded,
            title: t.translate('manage_store'),
            subtitle: _store?.name ?? '',
            onTap: () {
              if (_store != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreDetailsPage(storeId: _store!.id),
                  ),
                );
              }
            },
            colors: colors,
          ),
          const SizedBox(height: 28),
          _sectionHeader(t.translate('preferences'), colors),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: t.translate('theme'),
            subtitle: _themeModeLabel(appState!.themeMode, t),
            onTap: () => _showThemePicker(context),
            colors: colors,
          ),
          const SizedBox(height: 1),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: t.translate('language'),
            subtitle: _currentLang(t),
            onTap: () => _showLangPicker(context),
            colors: colors,
          ),
          const SizedBox(height: 28),
          _sectionHeader(t.translate('security'), colors),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: t.translate('security'),
            subtitle: t.translate('manage_security'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SecurityPage()),
            ),
            colors: colors,
          ),
          const SizedBox(height: 28),
          _sectionHeader(t.translate('info'), colors),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: t.translate('about_us'),
            subtitle: t.translate('team_credits'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutUsPage()),
            ),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _currentLang(AppLocalizations t) {
    switch (t.locale.languageCode) {
      case 'fr': return 'Français';
      case 'ar': return 'العربية';
      default: return 'English';
    }
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations t) {
    switch (mode) {
      case ThemeMode.dark: return t.translate('dark');
      case ThemeMode.light: return t.translate('light');
      case ThemeMode.system: return t.translate('system');
    }
  }

  void _showThemePicker(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final app = MyApp.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.translate('theme'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface),
            ),
            const SizedBox(height: 20),
            _OptionRow(
              icon: Icons.phone_android_rounded,
              label: t.translate('system'),
              selected: app!.themeMode == ThemeMode.system,
              onTap: () => _setTheme(ThemeMode.system),
              colors: colors,
            ),
            const SizedBox(height: 4),
            _OptionRow(
              icon: Icons.light_mode_rounded,
              label: t.translate('light'),
              selected: app.themeMode == ThemeMode.light,
              onTap: () => _setTheme(ThemeMode.light),
              colors: colors,
            ),
            const SizedBox(height: 4),
            _OptionRow(
              icon: Icons.dark_mode_rounded,
              label: t.translate('dark'),
              selected: app.themeMode == ThemeMode.dark,
              onTap: () => _setTheme(ThemeMode.dark),
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  void _setTheme(ThemeMode mode) {
    Navigator.pop(context);
    MyApp.of(context)?.setThemeMode(mode);
  }

  void _showLangPicker(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.translate('language'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.onSurface),
            ),
            const SizedBox(height: 20),
            _OptionRow(
              icon: Icons.language,
              label: 'English',
              selected: t.locale.languageCode == 'en',
              onTap: () => _setLang('en'),
              colors: colors,
            ),
            const SizedBox(height: 4),
            _OptionRow(
              icon: Icons.language,
              label: 'Français',
              selected: t.locale.languageCode == 'fr',
              onTap: () => _setLang('fr'),
              colors: colors,
            ),
            const SizedBox(height: 4),
            _OptionRow(
              icon: Icons.language,
              label: 'العربية',
              selected: t.locale.languageCode == 'ar',
              onTap: () => _setLang('ar'),
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  void _setLang(String code) {
    Navigator.pop(context);
    LocalePreferences.save(code);
    MyApp.of(context)?.setLocale(Locale(code));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colors;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: colors.onSurface.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18,
                color: selected ? colors.primary : colors.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Text(label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? colors.primary : colors.onSurface,
                ),
              ),
              const Spacer(),
              if (selected) Icon(Icons.check, size: 18, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
