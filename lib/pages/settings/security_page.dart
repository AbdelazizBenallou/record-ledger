import 'dart:convert';
import 'package:flutter/material.dart';
import '../../db/db_helper.dart';
import '../../db/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/store_settings.dart';
import '../../preferences/test_preferences.dart';
import '../../services/notification_service.dart';
import '../../utils/snackbar_utils.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _settingsRepo = SettingsRepository();
  StoreSettings? _settings;
  int _testMinutes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _settingsRepo.getByStoreId('default_store'),
      TestPreferences.getTestMinutes(),
    ]);
    if (!mounted) return;
    setState(() {
      _settings = results[0] as StoreSettings?;
      _testMinutes = results[1] as int;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(StoreSettings updated) async {
    if (_settings != null) {
      await _settingsRepo.update(updated);
    } else {
      await _settingsRepo.insert(updated);
    }
    setState(() => _settings = updated);
  }

  void _toggleLogin(bool value) {
    final updated = (_settings ?? StoreSettings(
      storeId: 'default_store',
      allowCreditLimitExceeded: false,
      loginEnabled: false,
    )).copyWith(loginEnabled: value);
    _saveSettings(updated);
  }

  void _showAddUser() {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final userCtrl = TextEditingController(text: _settings?.username ?? '');
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: EdgeInsets.only(
                    bottom: 20,
                    left: MediaQuery.of(ctx).size.width / 2 - 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_add_rounded,
                          size: 22, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.translate('add_user'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: userCtrl,
                  textDirection: t.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.translate('username'),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return t.translate('name_required');
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  textDirection: t.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.translate('password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return t.translate('name_required');
                    if (v.trim().length < 4) return 'Min 4 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  textDirection: t.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.translate('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v != passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final hash = base64.encode(utf8.encode(passCtrl.text.trim()));
                    final updated = (_settings ?? StoreSettings(
                      storeId: 'default_store',
                      allowCreditLimitExceeded: false,
                      loginEnabled: false,
                    )).copyWith(
                      username: userCtrl.text.trim(),
                      passwordHash: hash,
                      loginEnabled: true,
                    );
                    await _saveSettings(updated);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    showSuccessSnackBar(context, t.translate('user_added'));
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(t.translate('save')),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResetDataDialog() {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 24),
            const SizedBox(width: 10),
            Text(t.translate('reset_all_data')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.translate('reset_all_data_confirm'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: userCtrl,
                decoration: InputDecoration(
                  labelText: t.translate('username'),
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return t.translate('name_required');
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.translate('password'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return t.translate('name_required');
                  final hash = base64.encode(utf8.encode(v.trim()));
                  if (hash != _settings?.passwordHash) return t.translate('invalid_credentials');
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.translate('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final db = await DatabaseHelper.instance.database;
              await db.delete('credit_transactions');
              await db.delete('payments');
              await db.delete('customers');
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              showSuccessSnackBar(context, t.translate('data_reset'));
              _load();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.translate('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    final t = AppLocalizations.of(context);
    await NotificationService.instance.checkDuePayments('default_store');
    if (!mounted) return;
    showSuccessSnackBar(context, t.translate('test_notification_sent'));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(t.translate('security')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _sectionHeader(t.translate('enable_login'), colors),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              value: _settings?.loginEnabled ?? false,
              onChanged: _toggleLogin,
              title: Text(
                t.translate('enable_login'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
              secondary: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: _settings?.loginEnabled == true
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
              activeTrackColor: colors.primary.withValues(alpha: 0.4),
              activeThumbColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (_settings?.loginEnabled == true) ...[
            const SizedBox(height: 16),
            _sectionHeader(t.translate('users'), colors),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _ListTile(
                    icon: Icons.person_rounded,
                    title: _settings?.username ?? t.translate('no_users'),
                    subtitle: _settings?.username != null ? t.translate('current_user') : null,
                    colors: colors,
                    onTap: _showAddUser,
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16,
                      color: colors.outlineVariant.withValues(alpha: 0.3)),
                  _ListTile(
                    icon: Icons.person_add_rounded,
                    title: t.translate('add_user'),
                    subtitle: t.translate('add_user_desc'),
                    colors: colors,
                    onTap: _showAddUser,
                  ),
                  Divider(height: 1, indent: 56, endIndent: 16,
                      color: colors.outlineVariant.withValues(alpha: 0.3)),
                  InkWell(
                    onTap: _showResetDataDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: Icon(Icons.delete_forever_outlined,
                                size: 20, color: colors.error),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              t.translate('reset_all_data'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colors.error,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16,
                              color: colors.onSurface.withValues(alpha: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          _sectionHeader(t.translate('testing'), colors),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        t.translate('test_minutes'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_testMinutes ${t.translate('minutes')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _testMinutes.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 12,
                  label: '$_testMinutes min',
                  onChanged: (v) {
                    setState(() => _testMinutes = v.toInt());
                  },
                  onChangeEnd: (v) {
                    TestPreferences.setTestMinutes(v.toInt());
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 (${t.translate('off').toLowerCase()})',
                          style: TextStyle(
                            fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4),
                          )),
                      Text('120 ${t.translate('minutes')}',
                          style: TextStyle(
                            fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Divider(height: 1, indent: 16, endIndent: 16,
                    color: colors.outlineVariant.withValues(alpha: 0.3)),
                _ListTile(
                  icon: Icons.notifications_active_rounded,
                  title: t.translate('test_notification'),
                  subtitle: t.translate('test_notification_desc'),
                  colors: colors,
                  onTap: _testNotification,
                ),
              ],
            ),
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
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _ListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16,
                color: colors.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}
