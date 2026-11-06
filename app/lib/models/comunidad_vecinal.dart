import 'nivel.dart';

/// Grupo de vecinos de una comuna que se organizan para reciclar juntos.
/// Reutiliza el campo `comuna` del esquema de puntos_reciclaje.
class ComunidadVecinal {
  final String id;
  final String nombre;
  final String comuna;
  final String descripcion;
  final List<MiembroComunidad> miembros;
  final List<AnuncioComunidad> anuncios;

  const ComunidadVecinal({
    required this.id,
    required this.nombre,
    required this.comuna,
    required this.descripcion,
    required this.miembros,
    required this.anuncios,
  });

  ComunidadVecinal copyWith({
    List<MiembroComunidad>? miembros,
    List<AnuncioComunidad>? anuncios,
  }) {
    return ComunidadVecinal(
      id: id,
      nombre: nombre,
      comuna: comuna,
      descripcion: descripcion,
      miembros: miembros ?? this.miembros,
      anuncios: anuncios ?? this.anuncios,
    );
  }
}

class MiembroComunidad {
  final String nombre;
  final int puntos;
  final bool esOrganizador;
  final int avatarColorIndex;
  final bool esUsuarioActual;

  const MiembroComunidad({
    required this.nombre,
    required this.puntos,
    this.esOrganizador = false,
    this.avatarColorIndex = 0,
    this.esUsuarioActual = false,
  });

  Nivel get nivel => NivelInfo.paraPuntos(puntos);
}

class AnuncioComunidad {
  final String autor;
  final String hace;
  final String texto;
  final int avatarColorIndex;
  final bool esPropio;

  const AnuncioComunidad({
    required this.autor,
    required this.hace,
    required this.texto,
    this.avatarColorIndex = 0,
    this.esPropio = false,
  });
}
