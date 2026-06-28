import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isRtl = t.isRtl;

    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: value != null
          ? TextEditingController(text: _formatDate(value!))
          : null,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: value != null ? null : Theme.of(context).colorScheme.outline,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: t.translate('select_date'),
        hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        suffixIcon: value != null && onClear != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                ),
              )
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
