import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/team_member.dart';
import 'member_detail.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(t.translate('about_us')),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: teamMembers.length,
        itemBuilder: (context, index) {
          final member = teamMembers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MemberCard(member: member, colors: colors),
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final TeamMember member;
  final ColorScheme colors;
  const _MemberCard({required this.member, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MemberDetailPage(member: member)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: member.avatarColor.withValues(alpha: 0.2),
              child: Icon(
                member.avatarIcon,
                size: 32,
                color: member.avatarColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.role,
                    style: TextStyle(
                      fontSize: 13,
                      color: member.avatarColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
