import 'package:flutter/material.dart';
import '../../db/repositories/customer_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../widgets/empty_state/empty_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final CustomerRepository _repo = CustomerRepository();
  List<Customer> _dueToday = [];
  List<Customer> _overdue = [];
  bool _isLoading = true;

  static const _avatarColors = [
    Color(0xFF4F46E5),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFF2563EB),
    Color(0xFFD4D4D8),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.getDueToday('default_store'),
      _repo.getOverdue('default_store'),
    ]);
    if (!mounted) return;
    setState(() {
      _dueToday = results[0];
      _overdue = results[1];
      _isLoading = false;
    });
  }

  String _relativeTime(DateTime? date, AppLocalizations t) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} ${t.translate('days')}';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return '1m';
  }

  Color _avatarColor(String id) {
    final hash = id.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  String _initial(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('notifications')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dueToday.isEmpty && _overdue.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: t.translate('no_notifications'),
                  subtitle: t.translate('no_notifications_desc'),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _dueToday.length + _overdue.length,
                    itemBuilder: (context, index) {
                      if (index == 0 && _dueToday.isNotEmpty) {
                        return Column(
                          children: [
                            _buildSectionDivider(
                                Icons.schedule_rounded,
                                '${t.translate('due_today')}  ·  ${_dueToday.length}',
                                theme),
                            _buildNotificationTile(
                                _dueToday.first, true, t, theme),
                          ],
                        );
                      }
                      if (index == _dueToday.length && _overdue.isNotEmpty) {
                        return Column(
                          children: [
                            _buildSectionDivider(
                                Icons.warning_amber_rounded,
                                '${t.translate('overdue')}  ·  ${_overdue.length}',
                                theme),
                            _buildNotificationTile(
                                _overdue.first, false, t, theme),
                          ],
                        );
                      }
                      if (index < _dueToday.length) {
                        return _buildNotificationTile(
                            _dueToday[index], true, t, theme);
                      }
                      return _buildNotificationTile(
                          _overdue[index - _dueToday.length], false, t, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildSectionDivider(IconData icon, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.8,
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    Customer customer,
    bool isDueToday,
    AppLocalizations t,
    ThemeData theme,
  ) {
    final color = isDueToday ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final label = isDueToday
        ? t.translate('due_today')
        : _overdueLabel(customer.nextDueDate, t);
    final avatarColor = _avatarColor(customer.id);
    final initial = _initial(customer.name);
    final timeAgo = _relativeTime(customer.nextDueDate, t);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: null,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: avatarColor.withValues(alpha: 0.15),
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: avatarColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: customer.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: '  ${label.toLowerCase()}',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4)),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeAgo,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _overdueLabel(DateTime? dueDate, AppLocalizations t) {
    if (dueDate == null) return t.translate('overdue');
    final days = DateTime.now().difference(dueDate).inDays;
    if (days == 0) return t.translate('due_today');
    if (days == 1) return '1 ${t.translate('day')}';
    return '$days ${t.translate('days')}';
  }
}
