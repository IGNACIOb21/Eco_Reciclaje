// El horario se escribe como líneas "día: horas" (ej. `lun-vie: 9:00-18:00`)
// y viaja como objeto JSON. Estas dos funciones convierten entre ambos.

/// Lanza [FormatException] si alguna línea no tiene "día: horas".
Map<String, String> horarioDesdeTexto(String texto) {
  final horario = <String, String>{};
  for (final linea in texto.split('\n').map((l) => l.trim())) {
    if (linea.isEmpty) continue;
    final i = linea.indexOf(':');
    final clave = i > 0 ? linea.substring(0, i).trim() : '';
    final valor = i > 0 ? linea.substring(i + 1).trim() : '';
    if (clave.isEmpty || valor.isEmpty) {
      throw FormatException(
        'Cada línea del horario debe ser "día: horas".',
        linea,
      );
    }
    horario[clave] = valor;
  }
  return horario;
}

String horarioATexto(Map<String, String> horario) =>
    horario.entries.map((e) => '${e.key}: ${e.value}').join('\n');

const _dias = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];

int _ordenDia(String clave) {
  final c = clave
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  for (var i = 0; i < _dias.length; i++) {
    if (c.startsWith(_dias[i])) return i;
  }
  return _dias.length; // lo que no empieza con un día va al final
}

/// El `jsonb` de Postgres no conserva el orden en que se escribieron las
/// claves (queda ordenado por largo y alfabeto: "sáb" antes de "lun-vie").
/// Se ordena por el primer día de la semana de cada tramo.
Map<String, String> ordenarHorario(Map<String, String> horario) {
  final tramos = horario.entries.toList()
    ..sort((a, b) => _ordenDia(a.key).compareTo(_ordenDia(b.key)));
  return {for (final t in tramos) t.key: t.value};
}
