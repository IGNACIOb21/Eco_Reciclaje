import 'package:flutter_test/flutter_test.dart';

import 'package:recircula/utils/validacion_cuenta.dart';

void main() {
  test('formato de correo', () {
    expect(formatoCorreoValido('camila@gmail.com'), isTrue);
    expect(formatoCorreoValido(' ig.aguilar@duocuc.cl '), isTrue);
    expect(formatoCorreoValido('camila@gmail'), isFalse);
    expect(formatoCorreoValido('camila gmail.com'), isFalse);
    expect(formatoCorreoValido('cami la@gmail.com'), isFalse);
    expect(formatoCorreoValido('camila..r@gmail.com'), isFalse);
    expect(formatoCorreoValido('@gmail.com'), isFalse);
    expect(dominioDe('Camila@GMail.com'), 'gmail.com');
  });

  test('reglas de contraseña', () {
    expect(contrasenaValida('Recicla#2026'), isTrue);
    expect(contrasenaValida('Re#1abc'), isFalse, reason: 'menos de 8');
    expect(contrasenaValida('recicla#2026'), isFalse, reason: 'sin mayúscula');
    expect(contrasenaValida('RECICLA#2026'), isFalse, reason: 'sin minúscula');
    expect(contrasenaValida('Recicla#abcd'), isFalse, reason: 'sin número');
    expect(contrasenaValida('Recicla2026'), isFalse, reason: 'sin símbolo');
    expect(contrasenaValida('Recicla# 2026'), isFalse, reason: 'con espacio');
  });
}
