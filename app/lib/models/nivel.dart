/// Nivel del usuario, una fila de la tabla `niveles` de Supabase
/// (`nombre`, `puntos_minimos`). El nivel va por puntos **acumulados**, no
/// por saldo: un canje no baja de nivel.
class Nivel {
  final String nombre;
  final int puntosMinimos;

  const Nivel(this.nombre, this.puntosMinimos);

  /// Copia de la tabla `niveles` de la nube, para cuando todavía no se ha
  /// podido leer ni hay una copia guardada en el teléfono.
  static const porDefecto = [
    Nivel('Novato', 0),
    Nivel('Aprendiz', 200),
    Nivel('Pro', 600),
    Nivel('Experto', 1500),
    Nivel('Maestro', 3000),
  ];

  String get etiqueta =>
      nombre.startsWith('Recicla-') ? nombre : 'Recicla-$nombre';

  /// Nombre sin el prefijo "Recicla-", como lo muestra el Perfil.
  String get nombreCorto =>
      nombre.startsWith('Recicla-') ? nombre.substring(8) : nombre;

  /// Nivel que corresponde a [puntos] dentro de [tabla].
  static Nivel paraPuntos(int puntos, [List<Nivel> tabla = porDefecto]) {
    final ordenada = _ordenar(tabla);
    var actual = ordenada.first;
    for (final nivel in ordenada) {
      if (puntos >= nivel.puntosMinimos) actual = nivel;
    }
    return actual;
  }

  /// Nivel que sigue a este en [tabla], o null si es el último.
  Nivel? siguienteEn([List<Nivel> tabla = porDefecto]) {
    for (final nivel in _ordenar(tabla)) {
      if (nivel.puntosMinimos > puntosMinimos) return nivel;
    }
    return null;
  }

  static List<Nivel> _ordenar(List<Nivel> tabla) {
    final lista = tabla.isEmpty ? porDefecto : tabla;
    return [...lista]..sort((a, b) => a.puntosMinimos - b.puntosMinimos);
  }

  factory Nivel.fromJson(Map<String, dynamic> json) =>
      Nivel(json['nombre'] as String, (json['puntos_minimos'] as num).toInt());

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'puntos_minimos': puntosMinimos,
  };

  @override
  bool operator ==(Object other) =>
      other is Nivel &&
      other.nombre == nombre &&
      other.puntosMinimos == puntosMinimos;

  @override
  int get hashCode => Object.hash(nombre, puntosMinimos);
}
