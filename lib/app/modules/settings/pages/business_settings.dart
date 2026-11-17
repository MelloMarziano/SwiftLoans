import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/company_settings_sync.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/input_formatters.dart';
import '../../../core/widgets/form/form_fields.dart';
import '../../../core/widgets/form/form_section_card.dart';
import '../widgets/settings_page.dart';

class BusinessSettingsController extends GetxController {
  final _s = Get.find<SettingsService>();

  late final name = TextEditingController(text: _s.businessName.value);
  late final rnc = TextEditingController(text: _s.businessRnc.value);
  late final phone = TextEditingController(text: _s.businessPhone.value);
  late final address = TextEditingController(text: _s.businessAddress.value);
  late final footer = TextEditingController(text: _s.receiptFooter.value);

  final nameError = RxnString();

  @override
  void onClose() {
    for (final c in [name, rnc, phone, address, footer]) {
      c.dispose();
    }
    super.onClose();
  }

  void save() {
    if (name.text.trim().isEmpty) {
      nameError.value = 'Escribe el nombre del negocio';
      return;
    }
    nameError.value = null;
    _s.businessName.value = name.text.trim();
    _s.businessRnc.value = rnc.text.trim();
    _s.businessPhone.value = phone.text.trim();
    _s.businessAddress.value = address.text.trim();
    _s.receiptFooter.value = footer.text.trim();
    Get.back();
    showSettingsSaved('Datos del negocio actualizados.');
  }
}

class BusinessSettingsView extends GetView<BusinessSettingsController> {
  const BusinessSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      readOnly: !CompanySettingsSync.canEdit,
      title: 'Datos del negocio',
      onSave: controller.save,
      children: [
        FormSectionCard(
          icon: LucideIcons.building2,
          title: 'Negocio',
          child: Column(
            children: [
              Obx(
                () => TextFieldBox(
                  icon: LucideIcons.store,
                  label: 'Nombre del negocio',
                  required: true,
                  controller: controller.name,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  error: controller.nameError.value,
                ),
              ),
              const SizedBox(height: 10),
              FieldGrid(
                children: [
                  TextFieldBox(
                    icon: LucideIcons.idCard,
                    label: 'RNC',
                    controller: controller.rnc,
                    hint: 'Opcional',
                    keyboardType: TextInputType.number,
                  ),
                  TextFieldBox(
                    icon: LucideIcons.phone,
                    label: 'Teléfono',
                    controller: controller.phone,
                    hint: '809-000-0000',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [MaskedDigitsFormatter.phone()],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFieldBox(
                icon: LucideIcons.mapPin,
                label: 'Dirección',
                controller: controller.address,
                hint: 'Opcional',
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        FormSectionCard(
          icon: LucideIcons.receiptText,
          title: 'Recibo',
          child: TextFieldBox(
            icon: LucideIcons.messageSquare,
            label: 'Mensaje al pie del recibo',
            controller: controller.footer,
            hint: 'Ej.: Gracias por su pago',
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
