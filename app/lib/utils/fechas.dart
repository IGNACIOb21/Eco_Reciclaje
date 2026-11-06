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
