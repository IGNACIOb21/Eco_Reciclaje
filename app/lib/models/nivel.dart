enum Nivel { novato, aprendiz, pro, experto, maestro }

extension NivelInfo on Nivel {
  String get etiqueta => switch (this) {
    Nivel.novato => 'Recicla-Novato',
    Nivel.aprendiz => 'Recicla-Aprendiz',
    Nivel.pro => 'Recicla-Pro',
    Nivel.experto => 'Recicla-Experto',
    Nivel.maestro => 'Recicla-Maestro',
  };

  int get umbral => switch (this) {
    Nivel.novato => 0,
    Nivel.aprendiz => 50,
    Nivel.pro => 130,
    Nivel.experto => 200,
    Nivel.maestro => 400,
  };

  Nivel? get siguiente {
    final valores = Nivel.values;
    final i = valores.indexOf(this);
    return i + 1 < valores.length ? valores[i + 1] : null;
  }

  static Nivel paraPuntos(int puntos) {
    var actual = Nivel.novato;
    for (final nivel in Nivel.values) {
      if (puntos >= nivel.umbral) actual = nivel;
    }
    return actual;
  }
}
