import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLink {
  final IconData? icon;
  final FaIconData? faIcon;
  final String label;
  final String url;

  const SocialLink({
    this.icon,
    this.faIcon,
    required this.label,
    required this.url,
  });
}

class TeamMember {
  final String name;
  final String role;
  final String bio;
  final Color avatarColor;
  final IconData avatarIcon;
  final List<SocialLink> socialLinks;

  const TeamMember({
    required this.name,
    required this.role,
    required this.bio,
    required this.avatarColor,
    required this.avatarIcon,
    required this.socialLinks,
  });
}

final teamMembers = [
  TeamMember(
    name: 'Benallou Abdelaziz',
    role: 'Network Engineer',
    bio:
        'Network engineering student passionate about telecommunications, routing, and network security. Building tools to simplify academic life.',
    avatarColor: Colors.green,
    avatarIcon: CupertinoIcons.person_fill,
    socialLinks: [
      SocialLink(
        icon: CupertinoIcons.paperplane_fill,
        label: 'Telegram',
        url: 't.me/aziz_benallou',
      ),
      SocialLink(
        icon: CupertinoIcons.play_arrow_solid,
        label: 'YouTube',
        url: 'youtube.com/@abdelazizbenallou',
      ),
      SocialLink(
        icon: CupertinoIcons.link,
        label: 'LinkedIn',
        url: 'www.linkedin.com/in/abdelaziz-benallou-1a0428377',
      ),
      SocialLink(
        faIcon: FontAwesomeIcons.github,
        label: 'GitHub',
        url: 'github.com/AbdelazizBenallou',
      ),
    ],
  ),
];
