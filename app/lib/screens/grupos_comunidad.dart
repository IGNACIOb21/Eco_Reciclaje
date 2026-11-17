import 'package:flutter/material.dart';

import '../models/nivel.dart';
import '../models/perfil_local.dart';
import '../repositories/comunidades_repository.dart';
import '../state/perfil_local_controller.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';
import '../utils/snackbars.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/pill.dart';

/// Pestaña Grupos de Comunidad: vecinos organizándose para reciclar juntos.
/// Las comunidades, sus miembros y sus anuncios viven en Supabase
/// (`comunidad`, `miembro_comunidad`, `foro` y `publicacion_foro`).
class GruposComunidad extends StatefulWidget {
  final ComunidadesRepository? repositorio;

  const GruposComunidad({super.key, this.repositorio});

  @override
  State<GruposComunidad> createState() => _GruposComunidadState();
}

class _GruposComunidadState extends State<GruposComunidad> {
  late final ComunidadesRepository _repo =
      widget.repositorio ?? comunidadesPorDefecto();
  final TextEditingController _nuevoAnuncio = TextEditingController();

  late Future<List<ComunidadResumen>> _comunidades = _repo.comunidades();
  Future<List<Publicacion>>? _publicaciones;
  Future<List<MiembroResumen>>? _miembros;
  int? _cargadaPara;
  int _seccion = 0;
  bool _ocupado = false;

  @override
  void dispose() {
    _nuevoAnuncio.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final futuro = _repo.comunidades();
    setState(() {
      _comunidades = futuro;
      _cargadaPara = null;
    });
    await futuro.catchError((_) => <ComunidadResumen>[]);
  }

  /// Anuncios y miembros de la comunidad propia: se piden una vez por
  /// comunidad (y de nuevo al publicar o recargar).
  void _cargarDetalle(int id) {
    if (_cargadaPara == id) return;
    _cargadaPara = id;
    _publicaciones = _repo.publicaciones(id);
    _miembros = _repo.miembros(id);
  }

  Future<void> _accion(Future<void> Function() accion, {String? exito}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await accion();
      if (exito != null && mounted) mostrarSnackbar(context, exito);
      await _recargar();
    } on ComunidadException catch (e) {
      if (mounted) mostrarSnackbar(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _crear(String comuna) async {
    final datos = await showDialog<({String nombre, String descripcion})>(
      context: context,
      builder: (_) =>
          _CrearComunidadDialog(nombreInicial: 'Vecinos de $comuna'),
    );
    if (datos == null || datos.nombre.isEmpty || !mounted) return;
    await _accion(
      () => _repo.crear(
        nombre: datos.nombre,
        descripcion: datos.descripcion,
        comuna: comuna,
      ),
      exito: 'Creaste «${datos.nombre}». Invita a tus vecinos a sumarse.',
    );
  }

  Future<void> _salir(ComunidadResumen c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Salir de ${c.nombre}?'),
        content: const Text('Puedes volver a unirte cuando quieras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmar == true) await _accion(() => _repo.salir(c.id));
  }

  Future<void> _publicar(ComunidadResumen c) async {
    final texto = _nuevoAnuncio.text.trim();
    if (texto.isEmpty || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      await _repo.publicar(c.id, texto);
      _nuevoAnuncio.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _publicaciones = _repo.publicaciones(c.id);
      });
    } on ComunidadException catch (e) {
      if (mounted) mostrarSnackbar(context, e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = PerfilLocalScope.of(context).perfil;
    final colores = context.colores;

    return RefreshIndicator(
      onRefresh: _recargar,
      child: FutureBuilder<List<ComunidadResumen>>(
        future: _comunidades,
        builder: (context, snapshot) {
          final cargando =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final todas = snapshot.data ?? const <ComunidadResumen>[];
          final propias = todas.where((c) => c.esMiembro).toList();
          final mia = propias.isEmpty ? null : propias.first;
          final deMiComuna = todas
              .where((c) => !c.esMiembro && c.comuna == local.comuna)
              .toList();
          final otras = todas
              .where((c) => !c.esMiembro && c.comuna != local.comuna)
              .toList();
          if (mia != null) _cargarDetalle(mia.id);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                _Aviso(
                  texto: 'No pudimos cargar las comunidades. Desliza hacia abajo para reintentar.',
                )
              else if (mia != null) ...[
                _ComunidadCard(
                  comunidad: mia,
                  unido: true,
                  ocupado: _ocupado,
                  onUnirse: () {},
                  onSalir: () => _salir(mia),
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Anuncios'),
                      icon: Icon(Icons.campaign_outlined),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Miembros'),
                      icon: Icon(Icons.groups_outlined),
                    ),
                  ],
                  selected: {_seccion},
                  onSelectionChanged: (s) => setState(() => _seccion = s.first),
                ),
                const SizedBox(height: 14),
                if (_seccion == 0) ...[
                  _Composer(
                    controller: _nuevoAnuncio,
                    ocupado: _ocupado,
                    onPublicar: () => _publicar(mia),
                  ),
                  const SizedBox(height: 10),
                  _Anuncios(futuro: _publicaciones, local: local),
                ] else
                  _Miembros(futuro: _miembros, local: local),
                if (propias.length > 1) ...[
                  const SizedBox(height: 20),
                  const _Subtitulo('También participas en'),
                  for (final c in propias.skip(1))
                    _ComunidadCard(
                      comunidad: c,
                      unido: true,
                      ocupado: _ocupado,
                      onUnirse: () {},
                      onSalir: () => _salir(c),
                    ),
                ],
              ] else ...[
                if (deMiComuna.isEmpty)
                  _SinComunidadCard(
                    comuna: local.comuna,
                    onCrear: _ocupado ? null : () => _crear(local.comuna),
                  )
                else ...[
                  _Subtitulo('Comunidades en ${local.comuna}'),
                  for (final c in deMiComuna)
                    _ComunidadCard(
                      comunidad: c,
                      unido: false,
                      ocupado: _ocupado,
                      onUnirse: () => _accion(
                        () => _repo.unirse(c.id),
                        exito: 'Te uniste a ${c.nombre}.',
                      ),
                      onSalir: () {},
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : () => _crear(local.comuna),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear otra comunidad'),
                  ),
                ],
              ],
              if (!cargando && !snapshot.hasError && otras.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _Subtitulo('Otras comunidades'),
                for (final c in otras)
                  _ComunidadCard(
                    comunidad: c,
                    unido: false,
                    ocupado: _ocupado,
                    onUnirse: () => _accion(
                      () => _repo.unirse(c.id),
                      exito: 'Te uniste a ${c.nombre}.',
                    ),
                    onSalir: () {},
                  ),
              ],
              if (!cargando && mia != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Desliza hacia abajo para ver anuncios nuevos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colores.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Subtitulo extends StatelessWidget {
  final String texto;

  const _Subtitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

class _CrearComunidadDialog extends StatefulWidget {
  final String nombreInicial;

  const _CrearComunidadDialog({required this.nombreInicial});

  @override
  State<_CrearComunidadDialog> createState() => _CrearComunidadDialogState();
}

class _CrearComunidadDialogState extends State<_CrearComunidadDialog> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );
  final TextEditingController _descripcion = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear comunidad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre del grupo'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descripcion,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿De qué se trata? (opcional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          // El tema da a los botones ancho completo; en un diálogo, el suyo.
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => Navigator.of(context).pop((
            nombre: _nombre.text.trim(),
            descripcion: _descripcion.text.trim(),
          )),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _SinComunidadCard extends StatelessWidget {
  final String comuna;
  final VoidCallback? onCrear;

  const _SinComunidadCard({required this.comuna, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colores.primarioSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 36,
                color: colores.primarioTexto,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aún no hay una comunidad en $comuna',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea la tuya para coordinar con tus vecinos días de recolección, puntos llenos y más.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCrear,
                icon: const Icon(Icons.add),
                label: Text('Crear comunidad de $comuna'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComunidadCard extends StatelessWidget {
  final ComunidadResumen comunidad;
  final bool unido;
  final bool ocupado;
  final VoidCallback onUnirse;
  final VoidCallback onSalir;

  const _ComunidadCard({
    required this.comunidad,
    required this.unido,
    required this.ocupado,
    required this.onUnirse,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unido ? colores.fondoSecundario : colores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: unido ? null : Border.all(color: colores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comunidad.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: unido ? colores.secundario : colores.texto,
                  ),
                ),
              ),
              if (unido)
                Pill(
                  texto: comunidad.administro ? 'Organizas' : 'Miembro',
                  color: colores.primarioTexto,
                  alphaFondo: 0.15,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
            ],
          ),
          if (comunidad.descripcion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comunidad.descripcion,
              style: TextStyle(color: colores.texto, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: colores.secundario),
              const SizedBox(width: 6),
              Text(
                comunidad.miembros == 1
                    ? '1 miembro'
                    : '${comunidad.miembros} miembros',
                style: TextStyle(
                  color: colores.secundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.eco_outlined,
                size: 18,
                color: colores.recompensaTexto,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${comunidad.puntosSemana} pts esta semana',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colores.recompensaTexto,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              if (unido)
                TextButton(
                  onPressed: ocupado ? null : onSalir,
                  child: const Text('Salir'),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // El tema da a los botones ancho completo; en la fila, el suyo.
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: ocupado ? null : onUnirse,
                  child: const Text('Unirse'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool ocupado;
  final VoidCallback onPublicar;

  const _Composer({
    required this.controller,
    required this.ocupado,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 1,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Escribe un anuncio para tus vecinos…',
              isDense: true,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Publicar',
          onPressed: ocupado ? null : onPublicar,
          icon: const Icon(Icons.send),
          style: IconButton.styleFrom(
            backgroundColor: context.colores.primario,
            foregroundColor: context.colores.sobrePrimario,
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  final String texto;

  const _Aviso({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.superficieAlta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colores.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: colores.textoSecundario, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Anuncios extends StatelessWidget {
  final Future<List<Publicacion>>? futuro;
  final PerfilLocal local;

  const _Anuncios({required this.futuro, required this.local});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Publicacion>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const _Aviso(texto: 'No pudimos cargar los anuncios.');
        }
        final anuncios = snapshot.data ?? const [];
        if (anuncios.isEmpty) {
          return const _Aviso(
            texto:
                'Todavía no hay anuncios. Sé la primera persona en publicar.',
          );
        }
        return Column(
          children: [
            for (final a in anuncios) _AnuncioTile(anuncio: a, local: local),
          ],
        );
      },
    );
  }
}

class _AnuncioTile extends StatelessWidget {
  final Publicacion anuncio;
  final PerfilLocal local;

  const _AnuncioTile({required this.anuncio, required this.local});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarUsuario(
                  icono: anuncio.esPropia
                      ? local.avatarIcono
                      : AvatarIcono.persona,
                  color: anuncio.esPropia
                      ? local.avatarColor
                      : coloresAvatar[anuncio.autor.hashCode.abs() %
                            coloresAvatar.length],
                  tamano: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    anuncio.esPropia ? '${anuncio.autor} (tú)' : anuncio.autor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  haceTiempo(anuncio.fecha),
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(anuncio.texto),
          ],
        ),
      ),
    );
  }
}

class _Miembros extends StatelessWidget {
  final Future<List<MiembroResumen>>? futuro;
  final PerfilLocal local;

  const _Miembros({required this.futuro, required this.local});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MiembroResumen>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const _Aviso(texto: 'No pudimos cargar los miembros.');
        }
        final miembros = snapshot.data ?? const [];
        return Column(
          children: [
            for (final (i, m) in miembros.indexed)
              _MiembroTile(posicion: i + 1, miembro: m, local: local),
          ],
        );
      },
    );
  }
}

class _MiembroTile extends StatelessWidget {
  final int posicion;
  final MiembroResumen miembro;
  final PerfilLocal local;

  const _MiembroTile({
    required this.posicion,
    required this.miembro,
    required this.local,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final destacado = miembro.esYo;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: destacado ? colores.fondoSecundario : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$posicion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: posicion <= 3
                      ? colores.recompensaTexto
                      : colores.textoSecundario,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AvatarUsuario(
              icono: destacado ? local.avatarIcono : AvatarIcono.persona,
              color: destacado
                  ? local.avatarColor
                  : coloresAvatar[miembro.alias.hashCode.abs() %
                        coloresAvatar.length],
              tamano: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          destacado ? '${miembro.alias} (tú)' : miembro.alias,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (miembro.esOrganizador) ...[
                        const SizedBox(width: 6),
                        Pill(
                          texto: 'Organiza',
                          color: colores.recompensaTexto,
                          alphaFondo: 0.2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    Nivel.paraPuntos(miembro.puntos).etiqueta,
                    style: TextStyle(
                      color: colores.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${miembro.puntos} pts',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colores.primarioTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
