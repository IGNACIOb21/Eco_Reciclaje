import 'package:flutter/material.dart';

/// Grupos del catálogo de reportes (documento v3, sección 8).
enum GrupoReporte { estadoContenedor, informacionPunto, otros }

extension GrupoReporteInfo on GrupoReporte {
  String get etiqueta => switch (this) {
    GrupoReporte.estadoContenedor => 'Estado del contenedor',
    GrupoReporte.informacionPunto => 'Información del punto',
    GrupoReporte.otros => 'Otros',
  };
}

/// Los 11 valores del enum `tipo_reporte` de la base. [codigo] es el valor
/// que recibe `app_reportar_estado`.
enum TipoReporte {
  llenoSaturado(
    'lleno_saturado',
    'Lleno o saturado',
    'No queda espacio para depositar',
    Icons.delete_sweep_outlined,
    GrupoReporte.estadoContenedor,
  ),
  sucioResiduosAfuera(
    'sucio_residuos_afuera',
    'Sucio o con residuos afuera',
    'Basura acumulada fuera del contenedor',
    Icons.cleaning_services_outlined,
    GrupoReporte.estadoContenedor,
  ),
  danadoDestruido(
    'dañado_destruido',
    'Dañado o destruido',
    'Roto, quemado o vandalizado',
    Icons.report_problem_outlined,
    GrupoReporte.estadoContenedor,
  ),
  fueraDeServicio(
    'fuera_de_servicio',
    'Fuera de servicio',
    'Cerrado, retirado o inaccesible',
    Icons.block,
    GrupoReporte.estadoContenedor,
  ),
  sinSenalizacion(
    'sin_senalizacion',
    'Sin señalización',
    'No indica qué residuos recibe',
    Icons.signpost_outlined,
    GrupoReporte.informacionPunto,
  ),
  qrFaltanteDanado(
    'qr_faltante_danado',
    'QR faltante o dañado',
    'No se puede escanear el código',
    Icons.qr_code_2,
    GrupoReporte.informacionPunto,
  ),
  categoriasIncorrectas(
    'categorias_incorrectas',
    'Categorías incorrectas',
    'Recibe otros residuos que los indicados',
    Icons.category_outlined,
    GrupoReporte.informacionPunto,
  ),
  horarioIncorrecto(
    'horario_incorrecto',
    'Horario incorrecto',
    'No coincide con el horario real',
    Icons.schedule,
    GrupoReporte.informacionPunto,
  ),
  ubicacionIncorrecta(
    'ubicacion_incorrecta',
    'Ubicación incorrecta',
    'El punto está en otro lugar',
    Icons.wrong_location_outlined,
    GrupoReporte.informacionPunto,
  ),
  todoEnOrden(
    'todo_en_orden',
    'Todo en orden',
    'Confirma que el punto funciona bien',
    Icons.check_circle_outline,
    GrupoReporte.otros,
  ),
  otro(
    'otro',
    'Otro problema',
    'Algo que no está en la lista',
    Icons.more_horiz,
    GrupoReporte.otros,
  );

  final String codigo;
  final String etiqueta;
  final String descripcion;
  final IconData icono;
  final GrupoReporte grupo;

  const TipoReporte(
    this.codigo,
    this.etiqueta,
    this.descripcion,
    this.icono,
    this.grupo,
  );

  /// Largo mínimo del comentario: 20 caracteres en "Información del punto"
  /// (una breve descripción), 3 en "Otro" y 0 (opcional) en el resto. La
  /// base exige lo mismo (`comentario_obligatorio`).
  int get minimoComentario => switch (grupo) {
    GrupoReporte.informacionPunto => 20,
    _ => this == TipoReporte.otro ? 3 : 0,
  };

  bool get requiereComentario => minimoComentario > 0;

  /// Ejemplo que se muestra en el campo del comentario.
  String? get ayudaComentario => switch (this) {
    TipoReporte.sinSenalizacion =>
      'Ej: contenedor verde tipo campana, sin letrero',
    TipoReporte.qrFaltanteDanado => 'Ej: el QR está rayado y no se puede leer',
    TipoReporte.categoriasIncorrectas =>
      'Ej: dice vidrio, pero solo recibe latas',
    TipoReporte.horarioIncorrecto => 'Ej: abre de lunes a viernes de 9 a 14',
    TipoReporte.ubicacionIncorrecta =>
      'Ej: está en la esquina, frente al supermercado',
    _ => null,
  };

  /// Texto de la casilla que lleva al paso 2 (ej. "Realizar Lleno o
  /// saturado"). "Todo en orden" no es un problema: confirma el estado.
  String get textoRealizar => this == TipoReporte.todoEnOrden
      ? 'Realizar reporte de estado del punto'
      : 'Realizar $etiqueta';

  /// Título del paso 2: dice qué se está reportando.
  String get tituloReporte => this == TipoReporte.todoEnOrden
      ? 'Realizar reporte'
      : 'Reporte: $etiqueta';

  /// Solo en "Ubicación incorrecta" se puede enviar la ubicación real del
  /// punto (la posición GPS de quien reporta).
  bool get permiteUbicacion => this == TipoReporte.ubicacionIncorrecta;

  static TipoReporte? desdeCodigo(String codigo) {
    for (final t in values) {
      if (t.codigo == codigo) return t;
    }
    return null;
  }
}
