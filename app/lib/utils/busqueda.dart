import '../models/material_type.dart';
import '../models/punto_reciclaje.dart';

const _conTilde = 'áàäâéèëêíìïîóòöôúùüûñ';
const _sinTilde = 'aaaaeeeeiiiioooouuuun';

/// Minúsculas y sin tildes, para que "nunoa" encuentre "Ñuñoa".
String normalizarBusqueda(String texto) {
  final buffer = StringBuffer();
  for (final letra in texto.toLowerCase().trim().split('')) {
    final i = _conTilde.indexOf(letra);
    buffer.write(i == -1 ? letra : _sinTilde[i]);
  }
  return buffer.toString();
}

/// Puntos cuyo nombre, dirección, comuna o material ("vidrio", "pilas")
/// contienen [consulta]. Una consulta vacía devuelve la misma lista.
List<PuntoReciclaje> filtrarPuntos(
  List<PuntoReciclaje> puntos,
  String consulta,
) {
  final q = normalizarBusqueda(consulta);
  if (q.isEmpty) return puntos;
  return puntos
      .where(
        (p) => normalizarBusqueda(
          '${p.nombre} ${p.direccion} ${p.comuna} '
          '${p.materiales.map((m) => m.etiqueta).join(' ')}',
        ).contains(q),
      )
      .toList();
}
