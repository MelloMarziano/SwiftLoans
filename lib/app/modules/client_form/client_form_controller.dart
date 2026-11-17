import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/input_formatters.dart';
import '../../core/services/auth_backend.dart';
import '../../core/services/settings_service.dart';
import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';

/// Formulario de cliente. Si recibe el ID de un cliente como argumento,
/// edita; si no, crea uno nuevo.
class ClientFormController extends GetxController {
  final _repo = Get.find<ClientRepository>();

  /// Cliente que se está editando; null al crear.
  late final Client? editing;

  bool get isEditing => editing != null;

  final name = TextEditingController();
  final alias = TextEditingController();
  final document = TextEditingController();
  final occupation = TextEditingController();
  final phone = TextEditingController();
  final phone2 = TextEditingController();
  final address = TextEditingController();
  final sector = TextEditingController();
  final referenceName = TextEditingController();
  final referencePhone = TextEditingController();
  final notes = TextEditingController();

  final settings = Get.find<SettingsService>();
  late final route = settings.routes.first.obs;
  final submitted = false.obs;
  final isSaving = false.obs;

  /// Se incrementa al escribir, para refrescar los errores en vivo.
  final _edits = 0.obs;

  List<TextEditingController> get _all => [
    name,
    alias,
    document,
    occupation,
    phone,
    phone2,
    address,
    sector,
    referenceName,
    referencePhone,
    notes,
  ];

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments;
    editing = id is String ? _repo.byId(id) : null;

    final c = editing;
    if (c != null) {
      name.text = c.name;
      alias.text = c.alias ?? '';
      document.text = c.document ?? '';
      occupation.text = c.occupation ?? '';
      phone.text = c.phone ?? '';
      phone2.text = c.phone2 ?? '';
      address.text = c.address ?? '';
      sector.text = c.sector ?? '';
      referenceName.text = c.referenceName ?? '';
      referencePhone.text = c.referencePhone ?? '';
      notes.text = c.notes ?? '';
      route.value = c.route;
    }

    for (final controller in _all) {
      controller.addListener(() => _edits.value++);
    }
  }

  @override
  void onClose() {
    for (final c in _all) {
      c.dispose();
    }
    super.onClose();
  }

  Map<String, String> get _errors {
    final docDigits = MaskedDigitsFormatter.digitsOf(document.text);
    final phoneDigits = MaskedDigitsFormatter.digitsOf(phone.text);
    final phone2Digits = MaskedDigitsFormatter.digitsOf(phone2.text);
    final refDigits = MaskedDigitsFormatter.digitsOf(referencePhone.text);

    return {
      if (name.text.trim().length < 3) 'name': 'Escribe el nombre completo',
      if (docDigits.isNotEmpty && docDigits.length != 11)
        'document': 'La cédula tiene 11 dígitos',
      if (docDigits.length == 11 &&
          _repo.documentInUse(docDigits, exceptId: editing?.id))
        'document': 'Ya existe un cliente con esta cédula',
      if (phoneDigits.length != 10) 'phone': 'Teléfono de 10 dígitos',
      if (phone2Digits.isNotEmpty && phone2Digits.length != 10)
        'phone2': 'Teléfono de 10 dígitos',
      if (refDigits.isNotEmpty && refDigits.length != 10)
        'referencePhone': 'Teléfono de 10 dígitos',
    };
  }

  String? errorFor(String field) {
    _edits.value; // registra la dependencia para que el Obx se actualice
    return submitted.value ? _errors[field] : null;
  }

  Future<void> save() async {
    submitted.value = true;
    final errors = _errors;
    if (errors.isNotEmpty) {
      Get.snackbar(
        'Revisa el formulario',
        errors.values.join(' · '),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSaving.value = true;

    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final draft = Client(
      id: editing?.id ?? '',
      name: name.text.trim(),
      alias: clean(alias),
      document: clean(document),
      occupation: clean(occupation),
      phone: clean(phone),
      phone2: clean(phone2),
      address: clean(address),
      sector: clean(sector),
      route: route.value,
      referenceName: clean(referenceName),
      referencePhone: clean(referencePhone),
      notes: clean(notes),
      isActive: editing?.isActive ?? true,
      loanStatus: editing?.loanStatus ?? ClientLoanStatus.none,
      balance: editing?.balance ?? 0,
    );

    final Client saved;
    try {
      if (isEditing) {
        await _repo.update(draft);
        saved = draft;
      } else {
        saved = await _repo.create(draft);
      }
    } on AuthFailure catch (e) {
      Get.snackbar(
        'No se pudo guardar',
        e.message,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    } finally {
      isSaving.value = false;
    }

    // Devuelve el cliente para que quien abrió el formulario pueda usarlo
    // (p. ej. Nueva solicitud lo selecciona automáticamente).
    Get.back(result: saved);
    Get.snackbar(
      isEditing ? 'Cliente actualizado' : 'Cliente creado',
      saved.name,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
    );
  }
}
