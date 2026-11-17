/// Reglas para usuarios y contraseñas al crear cuentas.
abstract class UserValidators {
  static final _username = RegExp(r'^[a-z0-9._-]{3,30}$');

  static String? username(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return 'Escribe el usuario';
    if (v.contains('@')) return 'Sin @: solo el nombre de usuario';
    if (!_username.hasMatch(v)) {
      return '3 a 30 letras, números, punto o guion, sin espacios';
    }
    return null;
  }

  /// Firebase exige al menos 6 caracteres.
  static String? password(String value) =>
      value.length < 6 ? 'Mínimo 6 caracteres' : null;

  static String? name(String value) =>
      value.trim().length < 3 ? 'Escribe el nombre completo' : null;
}
