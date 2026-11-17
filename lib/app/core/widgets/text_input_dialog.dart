import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Diálogo con un campo de texto. Devuelve el texto o null si se cancela.
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue = '',
    this.confirmLabel = 'Guardar',
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.characters,
  });

  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;

  /// Devuelve el mensaje de error o null si el valor es válido.
  final String? Function(String)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  static Future<String?> show({
    required String title,
    required String label,
    String initialValue = '',
    String confirmLabel = 'Guardar',
    String? Function(String)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.characters,
  }) => Get.dialog<String>(
    TextInputDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
    ),
  );

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = value.isEmpty
        ? 'Escribe un valor'
        : widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Get.back(result: value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: widget.label,
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(widget.confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
