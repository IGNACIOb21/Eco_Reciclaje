import 'package:flutter/material.dart';

enum AvatarIcono {
  persona,
  hoja,
  reciclaje,
  estrella,
  mascota,
  arbol,
  sol,
  corazon,
}

extension AvatarIconoInfo on AvatarIcono {
  IconData get icono => switch (this) {
    AvatarIcono.persona => Icons.person,
    AvatarIcono.hoja => Icons.eco,
    AvatarIcono.reciclaje => Icons.recycling,
    AvatarIcono.estrella => Icons.star,
    AvatarIcono.mascota => Icons.pets,
    AvatarIcono.arbol => Icons.park,
    AvatarIcono.sol => Icons.wb_sunny,
    AvatarIcono.corazon => Icons.favorite,
  };
}

const coloresAvatar = [
  Color(0xFF2E9E5B),
  Color(0xFF3B82C4),
  Color(0xFFF2B705),
  Color(0xFFE07B39),
  Color(0xFF7C4DBE),
  Color(0xFFE0483F),
];

/// Personalización guardada solo en el dispositivo (ligada al device_id del
/// modo invitado) hasta que se defina si se persiste en Supabase.
class PerfilLocal {
  final String nombre;
  final AvatarIcono avatarIcono;
  final int avatarColorIndex;
  final String comuna;
  final bool modoEco;
  final String? comunidadUnidaId;

  const PerfilLocal({
    this.nombre = '',
    this.avatarIcono = AvatarIcono.persona,
    this.avatarColorIndex = 0,
    this.comuna = 'Ñuñoa',
    this.modoEco = false,
    this.comunidadUnidaId,
  });

  bool get esAnonimo => nombre.trim().isEmpty;
  String get nombreVisible => esAnonimo ? 'Usuario anónimo' : nombre.trim();
  Color get avatarColor =>
      coloresAvatar[avatarColorIndex.clamp(0, coloresAvatar.length - 1)];

  PerfilLocal copyWith({
    String? nombre,
    AvatarIcono? avatarIcono,
    int? avatarColorIndex,
    String? comuna,
    bool? modoEco,
    String? comunidadUnidaId,
    bool limpiarComunidad = false,
  }) {
    return PerfilLocal(
      nombre: nombre ?? this.nombre,
      avatarIcono: avatarIcono ?? this.avatarIcono,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      comuna: comuna ?? this.comuna,
      modoEco: modoEco ?? this.modoEco,
      comunidadUnidaId: limpiarComunidad
          ? null
          : (comunidadUnidaId ?? this.comunidadUnidaId),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'avatarIcono': avatarIcono.name,
    'avatarColorIndex': avatarColorIndex,
    'comuna': comuna,
    'modoEco': modoEco,
    'comunidadUnidaId': comunidadUnidaId,
  };

  factory PerfilLocal.fromJson(Map<String, dynamic> json) {
    return PerfilLocal(
      nombre: json['nombre'] as String? ?? '',
      avatarIcono:
          AvatarIcono.values.asNameMap()[json['avatarIcono']] ??
          AvatarIcono.persona,
      avatarColorIndex: json['avatarColorIndex'] as int? ?? 0,
      comuna: json['comuna'] as String? ?? 'Ñuñoa',
      modoEco: json['modoEco'] as bool? ?? false,
      comunidadUnidaId: json['comunidadUnidaId'] as String?,
    );
  }
}
