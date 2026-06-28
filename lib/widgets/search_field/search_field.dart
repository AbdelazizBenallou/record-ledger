import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSortTap;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isRtl = t.isRtl;

    return TextField(
      controller: controller,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: t.translate('search_hint'),
        hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        prefixIcon: const Icon(Icons.search, size: 22),
        suffixIcon: IconButton(
          icon: const Icon(Icons.tune, size: 22),
          onPressed: onSortTap,
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
          ),
        ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
