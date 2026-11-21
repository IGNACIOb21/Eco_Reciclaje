import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:recircula/escaneo/clasificador_escaneo.dart';
import 'package:recircula/escaneo/info_clase.dart';
import 'package:recircula/escaneo/resultado_escaneo.dart';
import 'package:recircula/models/material_type.dart';

/// Pruebas del escáner de Joaquín (rama `joaquin`, clasificador_test.dart),
/// adaptadas a lib/escaneo/, más el vínculo entre el modelo y la base.
void main() {
  group('nivelDeConfianza (umbrales de config.py)', () {
    test('95 % o más es segura', () {
      expect(nivelDeConfianza(0.95), Confianza.segura);
      expect(nivelDeConfianza(0.99), Confianza.segura);
    });

    test('entre 60 % y 95 % es dudosa', () {
      expect(nivelDeConfianza(0.60), Confianza.dudosa);
      expect(nivelDeConfianza(0.9499), Confianza.dudosa);
    });

    test('menos de 60 % es baja', () {
      expect(nivelDeConfianza(0.5999), Confianza.baja);
      expect(nivelDeConfianza(0.0), Confianza.baja);
    });
  });

  group('infoDeClase (clase del modelo → material de la app)', () {
    test('las clases con material equivalente se mapean', () {
      expect(infoDeClase('glass').material, TipoMaterial.vidrio);
      expect(infoDeClase('plastic').material, TipoMaterial.plastico);
      expect(infoDeClase('battery').material, TipoMaterial.pilas);
      expect(infoDeClase('paper').material, TipoMaterial.papel);
      expect(infoDeClase('cardboard').material, TipoMaterial.papel);
      expect(infoDeClase('metal').material, TipoMaterial.metal);
    });

    test('ropa, electrónicos y zapatos no tienen material en la app', () {
      expect(infoDeClase('clothes').material, isNull);
      expect(infoDeClase('electronic').material, isNull);
      expect(infoDeClase('shoes').material, isNull);
    });

    test('una clase desconocida se muestra con su nombre', () {
      final info = infoDeClase('clase_nueva');
      expect(info.nombre, 'clase_nueva');
      expect(info.material, isNull);
      expect(info.categoria, isEmpty);
    });
  });

  group('modelo y base', () {
    // categoria_residuo.codigo sembrados en backend/eco_reciclaje/04_seed.sql.
    const categoriasBase = {
      'vidrio',
      'papel',
      'plastico',
      'metal',
      'pilas',
      'latas',
      'tetra_pak',
      'aceite',
      'textil',
      'electronicos',
      'calzado',
    };

    final etiquetas = File('assets/modelo_escaneo/labels.txt')
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    test('labels.txt trae las 9 clases del modelo', () {
      expect(etiquetas, hasLength(9));
    });

    test('cada clase del modelo tiene nombre y consejo propios', () {
      for (final clase in etiquetas) {
        final info = infoDeClase(clase);
        expect(info.nombre, isNot(clase), reason: 'falta "$clase"');
        expect(info.consejo, isNotEmpty);
      }
    });

    test('cada clase se registra con una categoría que existe en la base', () {
      for (final clase in etiquetas) {
        expect(
          categoriasBase,
          contains(infoDeClase(clase).categoria),
          reason: '"$clase" no tiene categoria_residuo.codigo válido',
        );
      }
    });
  });

  group('prepararImagen', () {
    test('devuelve 224x224x3 con valores entre 0 y 255', () {
      final foto = img.Image(width: 300, height: 120);
      img.fill(foto, color: img.ColorRgb8(255, 0, 0));
      final datos = prepararImagen(img.encodePng(foto));

      expect(datos.length, 224 * 224 * 3);
      // Rojo puro: R=255, G=0, B=0 en el primer píxel (orden RGB).
      expect(datos[0], 255);
      expect(datos[1], 0);
      expect(datos[2], 0);
      expect(datos.every((v) => v >= 0 && v <= 255), isTrue);
    });

    test('falla con bytes que no son una imagen', () {
      expect(
        () => prepararImagen(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}
