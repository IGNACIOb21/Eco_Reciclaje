import 'package:flutter/material.dart';

import '../data/mock_comunidades.dart';
import '../models/comunidad_vecinal.dart';
import '../models/nivel.dart';
import '../models/perfil_local.dart';
import '../state/perfil_local_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/pill.dart';
import 'personalizar_perfil_sheet.dart';

/// Vecinos de una misma comuna organizándose para reciclar juntos. Estructura
/// visual completa con datos de ejemplo — la persistencia real (miembros,
/// anuncios) se conecta cuando se defina esa parte del esquema.
class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  final List<ComunidadVecinal> _comunidades = List.of(mockComunidades);
  final TextEditingController _nuevoAnuncio = TextEditingController();
  int _seccion = 0;

  @override
  void dispose() {
    _nuevoAnuncio.dispose();
    super.dispose();
  }

  ComunidadVecinal? _comunidadDe(String comuna) {
    for (final c in _comunidades) {
      if (c.comuna == comuna) return c;
    }
    return null;
  }

  Future<void> _crearComunidad(PerfilLocalController controller) async {
    final comuna = controller.perfil.comuna;
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) =>
          _CrearComunidadDialog(nombreInicial: 'Vecinos de $comuna'),
    );
    if (nombre == null || nombre.isEmpty || !mounted) return;

    final nueva = ComunidadVecinal(
      id: 'local-${comuna.toLowerCase().replaceAll(' ', '-')}',
      nombre: nombre,
      comuna: comuna,
      descripcion: 'Comunidad creada por ti. Invita a tus vecinos a sumarse.',
      miembros: const [],
      anuncios: const [],
    );
    setState(() => _comunidades.add(nueva));
    await controller.actualizar(
      controller.perfil.copyWith(comunidadUnidaId: nueva.id),
    );
  }

  void _publicar(ComunidadVecinal comunidad, PerfilLocal local) {
    final texto = _nuevoAnuncio.text.trim();
    if (texto.isEmpty) return;
    final anuncio = AnuncioComunidad(
      autor: local.nombreVisible,
      hace: 'ahora',
      texto: texto,
      avatarColorIndex: local.avatarColorIndex,
      esPropio: true,
    );
    setState(() {
      final i = _comunidades.indexWhere((c) => c.id == comunidad.id);
      _comunidades[i] = comunidad.copyWith(
        anuncios: [anuncio, ...comunidad.anuncios],
      );
      _nuevoAnuncio.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = PerfilLocalScope.of(context);
    final local = controller.perfil;
    final colores = context.colores;
    final comunidad = _comunidadDe(local.comuna);
    final unido = comunidad != null && local.comunidadUnidaId == comunidad.id;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Comunidad',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: colores.textoSecundario,
                ),
                const SizedBox(width: 4),
                Text(
                  local.comuna,
                  style: TextStyle(color: colores.textoSecundario),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => mostrarPersonalizarPerfil(context),
                  child: const Text('Cambiar'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (comunidad == null)
              _SinComunidadCard(
                comuna: local.comuna,
                onCrear: () => _crearComunidad(controller),
              )
            else ...[
              _ComunidadCard(
                comunidad: comunidad,
                unido: unido,
                onUnirse: () => controller.actualizar(
                  local.copyWith(comunidadUnidaId: comunidad.id),
                ),
                onSalir: () => controller.actualizar(
                  local.copyWith(limpiarComunidad: true),
                ),
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
                if (unido)
                  _Composer(
                    controller: _nuevoAnuncio,
                    onPublicar: () => _publicar(comunidad, local),
                  )
                else
                  _Aviso(texto: 'Únete a la comunidad para publicar anuncios.'),
                const SizedBox(height: 10),
                if (comunidad.anuncios.isEmpty)
                  _Aviso(
                    texto: 'Todavía no hay anuncios. Sé la primera persona en publicar.',
                  )
                else
                  for (final anuncio in comunidad.anuncios)
                    _AnuncioTile(anuncio: anuncio),
              ] else ...[
                for (final (i, miembro) in _miembrosOrdenados(
                  comunidad,
                  local,
                  unido,
                ).indexed)
                  _MiembroTile(
                    posicion: i + 1,
                    miembro: miembro,
                    avatarIcono: local.avatarIcono,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<MiembroComunidad> _miembrosOrdenados(
    ComunidadVecinal comunidad,
    PerfilLocal local,
    bool unido,
  ) {
    final lista = [
      ...comunidad.miembros,
      if (unido)
        MiembroComunidad(
          nombre: local.nombreVisible,
          puntos: UsuarioScope.of(context).usuario?.puntosTotales ?? 0,
          avatarColorIndex: local.avatarColorIndex,
          esOrganizador: comunidad.miembros.isEmpty,
          esUsuarioActual: true,
        ),
    ]..sort((a, b) => b.puntos.compareTo(a.puntos));
    return lista;
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

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear comunidad'),
      content: TextField(
        controller: _nombre,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre del grupo'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_nombre.text.trim()),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _SinComunidadCard extends StatelessWidget {
  final String comuna;
  final VoidCallback onCrear;

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
                color: colores.primario.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 36,
                color: colores.primario,
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
  final ComunidadVecinal comunidad;
  final bool unido;
  final VoidCallback onUnirse;
  final VoidCallback onSalir;

  const _ComunidadCard({
    required this.comunidad,
    required this.unido,
    required this.onUnirse,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final totalMiembros = comunidad.miembros.length + (unido ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colores.fondoSecundario,
        borderRadius: BorderRadius.circular(20),
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
                    color: colores.secundario,
                  ),
                ),
              ),
              if (unido)
                Pill(
                  texto: 'Miembro',
                  color: colores.primario,
                  alphaFondo: 0.2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comunidad.descripcion,
            style: TextStyle(color: colores.texto, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: colores.secundario),
              const SizedBox(width: 6),
              Text(
                '$totalMiembros miembros',
                style: TextStyle(
                  color: colores.secundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (unido)
                TextButton(onPressed: onSalir, child: const Text('Salir'))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: onUnirse,
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
  final VoidCallback onPublicar;

  const _Composer({required this.controller, required this.onPublicar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Escribe un anuncio para tus vecinos…',
              isDense: true,
            ),
            onSubmitted: (_) => onPublicar(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onPublicar,
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

class _AnuncioTile extends StatelessWidget {
  final AnuncioComunidad anuncio;

  const _AnuncioTile({required this.anuncio});

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
                  icono: AvatarIcono.persona,
                  color: coloresAvatar[anuncio.avatarColorIndex],
                  tamano: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    anuncio.esPropio ? '${anuncio.autor} (tú)' : anuncio.autor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  anuncio.hace,
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

class _MiembroTile extends StatelessWidget {
  final int posicion;
  final MiembroComunidad miembro;
  final AvatarIcono avatarIcono;

  const _MiembroTile({
    required this.posicion,
    required this.miembro,
    required this.avatarIcono,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final destacado = miembro.esUsuarioActual;

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
                      ? colores.acento
                      : colores.textoSecundario,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AvatarUsuario(
              icono: destacado ? avatarIcono : AvatarIcono.persona,
              color: coloresAvatar[miembro.avatarColorIndex],
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
                          destacado ? '${miembro.nombre} (tú)' : miembro.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (miembro.esOrganizador) ...[
                        const SizedBox(width: 6),
                        Pill(
                          texto: 'Organiza',
                          color: colores.acento,
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
                    miembro.nivel.etiqueta,
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
                color: colores.primario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
