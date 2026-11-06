import '../models/comunidad_vecinal.dart';

/// Comunidades de ejemplo, una por comuna donde ya "existe" organización
/// vecinal. Las comunas sin entrada aquí muestran el flujo de "crear
/// comunidad". Sin conexión a Supabase todavía.
final mockComunidades = <ComunidadVecinal>[
  const ComunidadVecinal(
    id: 'nunoa',
    nombre: 'Vecinos Reciclan Ñuñoa',
    comuna: 'Ñuñoa',
    descripcion:
        'Nos juntamos cada dos sábados en Plaza Ñuñoa para llevar vidrio y '
        'cartón al punto limpio. Todos bienvenidos.',
    miembros: [
      MiembroComunidad(
        nombre: 'Javiera R.',
        puntos: 412,
        esOrganizador: true,
        avatarColorIndex: 4,
      ),
      MiembroComunidad(nombre: 'Tomás V.', puntos: 305, avatarColorIndex: 1),
      MiembroComunidad(
        nombre: 'Constanza M.',
        puntos: 268,
        avatarColorIndex: 3,
      ),
      MiembroComunidad(
        nombre: 'Valentina P.',
        puntos: 190,
        avatarColorIndex: 2,
      ),
      MiembroComunidad(nombre: 'Ignacio T.', puntos: 140, avatarColorIndex: 0),
      MiembroComunidad(nombre: 'Florencia A.', puntos: 96, avatarColorIndex: 5),
    ],
    anuncios: [
      AnuncioComunidad(
        autor: 'Javiera R.',
        hace: 'hace 2 h',
        texto: 'El sábado juntamos vidrio en la plaza a las 11:00. Traigan las botellas limpias 🙌',
        avatarColorIndex: 4,
      ),
      AnuncioComunidad(
        autor: 'Tomás V.',
        hace: 'ayer',
        texto: 'El contenedor de Irarrázaval con Suecia está lleno, mejor usar el de la Municipalidad.',
        avatarColorIndex: 1,
      ),
      AnuncioComunidad(
        autor: 'Constanza M.',
        hace: 'hace 3 días',
        texto: 'Tengo cajas de cartón grandes si alguien necesita para mover cosas.',
        avatarColorIndex: 3,
      ),
    ],
  ),
  const ComunidadVecinal(
    id: 'providencia',
    nombre: 'Providencia Circular',
    comuna: 'Providencia',
    descripcion: 'Coordinamos retiros de pilas y electrónicos una vez al mes.',
    miembros: [
      MiembroComunidad(
        nombre: 'Benjamín S.',
        puntos: 221,
        esOrganizador: true,
        avatarColorIndex: 1,
      ),
      MiembroComunidad(nombre: 'Matías G.', puntos: 58, avatarColorIndex: 3),
      MiembroComunidad(nombre: 'Josefa L.', puntos: 22, avatarColorIndex: 5),
    ],
    anuncios: [
      AnuncioComunidad(
        autor: 'Benjamín S.',
        hace: 'hace 5 h',
        texto:
            'Retiro de pilas este viernes en Metro Los Leones, 18:00 a 20:00.',
        avatarColorIndex: 1,
      ),
    ],
  ),
  const ComunidadVecinal(
    id: 'macul',
    nombre: 'Macul Recicla',
    comuna: 'Macul',
    descripcion: 'Grupo de la Villa Macul para juntar plástico y latas.',
    miembros: [
      MiembroComunidad(
        nombre: 'Camila O.',
        puntos: 176,
        esOrganizador: true,
        avatarColorIndex: 2,
      ),
      MiembroComunidad(nombre: 'Diego F.', puntos: 84, avatarColorIndex: 0),
    ],
    anuncios: [
      AnuncioComunidad(
        autor: 'Camila O.',
        hace: 'hace 1 día',
        texto: 'Necesitamos alguien con auto para llevar las latas el domingo.',
        avatarColorIndex: 2,
      ),
    ],
  ),
];
