/// Reglas de correo y contraseña del registro. Son validaciones de UX: la
/// contraseña además la valida Supabase Auth (largo mínimo y tipos de
/// caracteres configurados en el proyecto), así que no es la única defensa.
library;

final _correo = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
);

/// Estructura de correo (usuario@dominio.tld), sin espacios ni puntos dobles.
bool formatoCorreoValido(String correo) {
  final c = correo.trim();
  return c.length <= 254 && !c.contains('..') && _correo.hasMatch(c);
}

/// Dominio del correo (lo que va después de la @), en minúsculas.
String dominioDe(String correo) => correo.trim().split('@').last.toLowerCase();

/// Una regla de contraseña que se muestra al usuario mientras escribe.
class ReglaContrasena {
  final String texto;
  final bool Function(String) cumple;

  const ReglaContrasena(this.texto, this.cumple);
}

final reglasContrasena = [
  ReglaContrasena('Mínimo 8 caracteres', (p) => p.length >= 8),
  ReglaContrasena(
    'Una letra mayúscula',
    (p) => RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(p),
  ),
  ReglaContrasena(
    'Una letra minúscula',
    (p) => RegExp(r'[a-záéíóúñ]').hasMatch(p),
  ),
  ReglaContrasena('Un número', (p) => RegExp(r'[0-9]').hasMatch(p)),
  ReglaContrasena(
    'Un carácter especial o símbolo',
    (p) => RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑáéíóúñ\s]').hasMatch(p),
  ),
];

/// Reglas que no se listan en pantalla pero igual se exigen.
bool contrasenaSinEspacios(String p) => !RegExp(r'\s').hasMatch(p);

bool contrasenaValida(String p) =>
    contrasenaSinEspacios(p) && reglasContrasena.every((r) => r.cumple(p));
