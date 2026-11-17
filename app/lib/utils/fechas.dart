const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "marzo 2026", sin depender de intl para un solo formato.
String mesYAnio(DateTime fecha) => '${_meses[fecha.month - 1]} ${fecha.year}';

/// "hoy", "ayer", "hace 3 días", "hace 2 semanas", "hace 4 meses" respecto
/// de [ahora] (por defecto, este momento).
String haceTiempo(DateTime fecha, {DateTime? ahora}) {
  final dias = (ahora ?? DateTime.now()).difference(fecha).inDays;
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 7) return 'hace $dias días';
  if (dias < 30) {
    final semanas = dias ~/ 7;
    return semanas == 1 ? 'hace 1 semana' : 'hace $semanas semanas';
  }
  final meses = dias ~/ 30;
  return meses <= 1 ? 'hace 1 mes' : 'hace $meses meses';
}
