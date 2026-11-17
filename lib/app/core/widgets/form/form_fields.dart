import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../utils/input_formatters.dart';
import 'field_box.dart';

/// Campo de texto dentro de una [FieldBox].
class TextFieldBox extends StatelessWidget {
  const TextFieldBox({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.isMoney = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.obscure = false,
    this.required = false,
    this.error,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.inputFormatters,
    this.trailing,
  });

  /// Campo de monto en pesos, con separador de miles.
  const TextFieldBox.money({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.required = false,
    this.error,
    this.trailing,
  }) : hint = '0.00',
       prefix = null,
       isMoney = true,
       textCapitalization = TextCapitalization.none,
       textInputAction = TextInputAction.next,
       maxLines = 1,
       obscure = false,
       keyboardType = const TextInputType.numberWithOptions(decimal: true),
       inputFormatters = null;

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;

  /// Aplica separador de miles y 2 decimales.
  final bool isMoney;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final int maxLines;

  /// Oculta el texto (contraseñas).
  final bool obscure;
  final bool required;
  final String? error;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = FieldBox.valueStyle(context);

    return FieldBox(
      icon: icon,
      label: label,
      required: required,
      error: error,
      trailing: trailing,
      child: Row(
        children: [
          if (prefix != null) Text(prefix!, style: style),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textInputAction: textInputAction,
              maxLines: obscure ? 1 : maxLines,
              minLines: 1,
              obscureText: obscure,
              autocorrect: !obscure,
              enableSuggestions: !obscure,
              inputFormatters:
                  inputFormatters ?? (isMoney ? [MoneyInputFormatter()] : null),
              style: style,
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: style.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de selección con menú desplegable.
class SelectFieldBox<T> extends StatelessWidget {
  const SelectFieldBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tooltip: label,
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Expanded(child: Text(optionLabel(option))),
                if (option == value)
                  const Icon(
                    LucideIcons.check,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
      ],
      child: IgnorePointer(
        child: FieldBox(
          icon: icon,
          label: label,
          trailing: const Icon(LucideIcons.chevronDown, size: 20),
          onTap: () {},
          child: Text(
            optionLabel(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FieldBox.valueStyle(context),
          ),
        ),
      ),
    );
  }
}

/// Distribuye campos en 2 columnas; en pantallas muy angostas, en 1.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 320 ? 1 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
