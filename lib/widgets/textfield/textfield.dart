import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.of(context).isRtl;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.4,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintTextDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20)
            : null,
        suffixIcon: suffix,
        alignLabelWithHint: maxLines != null && maxLines! > 1,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
