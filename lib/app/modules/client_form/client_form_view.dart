import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/form/form_fields.dart';
import '../../core/widgets/form/form_section_card.dart';
import '../root/root_controller.dart';
import '../root/widgets/app_shell.dart';
import 'client_form_controller.dart';

class ClientFormView extends GetView<ClientFormController> {
  const ClientFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = controller.isEditing ? 'Editar cliente' : 'Nuevo cliente';

    return AppShell(
      title: title,
      showBack: true,
      activeTab: RootController.clients,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 1000;
            final gap = context.sized(12, 20);

            const personal = _PersonalCard();
            const contact = _ContactCard();
            const reference = _ReferenceCard();
            const notes = _NotesCard();

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.sized(14, 32),
                context.sized(14, 24),
                context.sized(14, 32),
                context.isCompact ? 120 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(title: title),
                      SizedBox(height: gap),
                      if (twoColumns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  personal,
                                  SizedBox(height: gap),
                                  reference,
                                ],
                              ),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: Column(
                                children: [
                                  contact,
                                  SizedBox(height: gap),
                                  notes,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        personal,
                        SizedBox(height: gap),
                        contact,
                        SizedBox(height: gap),
                        reference,
                        SizedBox(height: gap),
                        notes,
                      ],
                      SizedBox(height: context.sized(18, 24)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: twoColumns ? 420 : double.infinity,
                          ),
                          child: const _SaveButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends GetView<ClientFormController> {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final size = context.sized(48.0, 56.0);

    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            controller.isEditing ? LucideIcons.userPen : LucideIcons.userPlus,
            size: size * 0.5,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isEditing
                    ? 'ID: ${controller.editing!.id} · Actualiza los datos del cliente'
                    : 'Registra los datos del cliente',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: context.sized(13, 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalCard extends GetView<ClientFormController> {
  const _PersonalCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.idCard,
      title: 'Datos personales',
      child: Obx(
        () => Column(
          children: [
            TextFieldBox(
              icon: LucideIcons.user,
              label: 'Nombre completo',
              required: true,
              controller: controller.name,
              hint: 'Nombre y apellido',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              error: controller.errorFor('name'),
            ),
            const SizedBox(height: 10),
            FieldGrid(
              children: [
                TextFieldBox(
                  icon: LucideIcons.smile,
                  label: 'Apodo',
                  controller: controller.alias,
                  hint: 'Opcional',
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                TextFieldBox(
                  icon: LucideIcons.idCard,
                  label: 'Cédula',
                  controller: controller.document,
                  hint: '000-0000000-0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [MaskedDigitsFormatter.cedula()],
                  error: controller.errorFor('document'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFieldBox(
              icon: LucideIcons.briefcase,
              label: 'Ocupación / lugar de trabajo',
              controller: controller.occupation,
              hint: 'Opcional',
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends GetView<ClientFormController> {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.mapPin,
      title: 'Contacto y dirección',
      child: Obx(
        () => Column(
          children: [
            FieldGrid(
              children: [
                TextFieldBox(
                  icon: LucideIcons.phone,
                  label: 'Teléfono',
                  required: true,
                  controller: controller.phone,
                  hint: '809-000-0000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [MaskedDigitsFormatter.phone()],
                  error: controller.errorFor('phone'),
                ),
                TextFieldBox(
                  icon: LucideIcons.phone,
                  label: 'Teléfono 2',
                  controller: controller.phone2,
                  hint: 'Opcional',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [MaskedDigitsFormatter.phone()],
                  error: controller.errorFor('phone2'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFieldBox(
              icon: LucideIcons.house,
              label: 'Dirección',
              controller: controller.address,
              hint: 'Calle, número, referencia',
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            FieldGrid(
              children: [
                TextFieldBox(
                  icon: LucideIcons.map,
                  label: 'Sector / Ciudad',
                  controller: controller.sector,
                  hint: 'Opcional',
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                ),
                SelectFieldBox<String>(
                  icon: LucideIcons.route,
                  label: 'Ruta / Oficina',
                  value: controller.route.value,
                  options: controller.settings.routes,
                  optionLabel: (r) => r,
                  onChanged: (r) => controller.route.value = r,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceCard extends GetView<ClientFormController> {
  const _ReferenceCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.contact,
      title: 'Referencia',
      child: Obx(
        () => FieldGrid(
          children: [
            TextFieldBox(
              icon: LucideIcons.user,
              label: 'Nombre',
              controller: controller.referenceName,
              hint: 'Opcional',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            TextFieldBox(
              icon: LucideIcons.phone,
              label: 'Teléfono',
              controller: controller.referencePhone,
              hint: 'Opcional',
              keyboardType: TextInputType.phone,
              inputFormatters: [MaskedDigitsFormatter.phone()],
              error: controller.errorFor('referencePhone'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends GetView<ClientFormController> {
  const _NotesCard();

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      icon: LucideIcons.stickyNote,
      title: 'Notas',
      child: TextFieldBox(
        icon: LucideIcons.fileText,
        label: 'Observaciones',
        controller: controller.notes,
        hint: 'Opcional',
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.newline,
        maxLines: 4,
      ),
    );
  }
}

class _SaveButton extends GetView<ClientFormController> {
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final saving = controller.isSaving.value;

      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: saving ? null : controller.save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shadowColor: Colors.transparent,
            minimumSize: Size.fromHeight(context.sized(52, 58)),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: context.sized(16, 17),
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.save, size: 22),
          label: Text(
            saving
                ? 'Guardando...'
                : controller.isEditing
                ? 'Guardar cambios'
                : 'Guardar cliente',
          ),
        ),
      );
    });
  }
}
