import 'package:flutter/material.dart';

import '../models/nivel.dart';
import '../models/perfil_usuario.dart';
import '../models/reto.dart';
import '../models/resumen_puntos.dart';
import '../models/usuario.dart';
import '../repositories/cuenta_repository.dart';
import '../repositories/cuenta_repository_mock.dart';
import '../repositories/cuenta_repository_supabase.dart';
import '../services/haptica.dart';
import '../services/recordatorio_racha_store.dart';
import '../services/supabase_service.dart';
import '../state/perfil_local_controller.dart';
import '../state/tema_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_themes.dart';
import '../theme/app_theme.dart';
import '../theme/tipografia.dart';
import '../widgets/actividad_puntos_tile.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/icono_bonsai.dart';
import '../widgets/permisos_ajustes.dart';
import '../repositories/acciones_por_defecto.dart';
import '../repositories/beneficios_por_defecto.dart';
import '../repositories/gamificacion_por_defecto.dart';
import '../repositories/retos_por_defecto.dart';
import '../repositories/retos_repository.dart';
import 'beneficios_screen.dart';
import 'guia_reciclaje_screen.dart';
import 'retos_screen.dart';
import 'mis_reportes_screen.dart';
import 'para_reclamar_screen.dart';
import 'iniciar_sesion_screen.dart';
import 'personalizar_perfil_sheet.dart';
import 'registro_cuenta_screen.dart';

class PerfilScreen extends StatelessWidget {
  /// Solo para tests: los logros que se muestran como insignias. Por defecto
  /// [retosPorDefecto].
  final RetosRepository? retos;

  const PerfilScreen({super.key, this.retos});

  @override
  Widget build(BuildContext context) {
    final controller = PerfilLocalScope.of(context);
    final local = controller.perfil;
    final usuarioCtrl = UsuarioScope.of(context);
    final usuario = usuarioCtrl.usuario;
    // Todo sale de la cuenta (puntos, fecha de alta, estadísticas, logros y
    // actividad); mientras carga no se muestra nada inventado.
    final perfil = usuario == null ? null : PerfilUsuario.desdeUsuario(usuario);
    final colores = context.colores;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // Único acceso a "Personalizar perfil" (nombre, ícono y comuna).
            Semantics(
              button: true,
              label: 'Personalizar perfil',
              child: InkWell(
                key: const Key('perfil-personalizar'),
                borderRadius: BorderRadius.circular(28),
                onTap: () => mostrarPersonalizarPerfil(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: colores.primario.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: AvatarUsuario(
                              icono: local.avatarIcono,
                              color: local.avatarColor,
                              tamano: 92,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: colores.primario,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: colores.sobrePrimario,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        local.nombreVisible,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perfil == null
                            ? local.comuna
                            : 'Reciclando desde ${perfil.miembroDesde} · ${local.comuna}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colores.textoSecundario,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (usuarioCtrl.resumen != null)
              _NivelCard(
                resumen: usuarioCtrl.resumen!,
                desdeCopia: usuarioCtrl.resumenDesdeCopia,
                onReintentar: usuarioCtrl.cargar,
              )
            else
              _NivelPendiente(
                error: usuarioCtrl.error != null && !usuarioCtrl.cargando,
                onReintentar: usuarioCtrl.cargar,
              ),
            const SizedBox(height: 12),
            _Cifras(
              cifras: [
                (
                  const Key('perfil-stat-reciclados'),
                  '${perfil?.objetosEscaneados ?? "–"}',
                  'objetos reciclados',
                ),
                (
                  const Key('perfil-racha'),
                  '${perfil?.racha ?? "–"}',
                  perfil?.racha == 1 ? 'día de racha' : 'días de racha',
                ),
              ],
            ),
            const SizedBox(height: 22),
            _InsigniasPerfil(repositorio: retos ?? retosPorDefecto()),
            const SizedBox(height: 16),
            if (usuario != null && usuario.esInvitado) ...[
              _CuentaCard(usuario: usuario),
              const SizedBox(height: 16),
            ],
            const _Preferencias(),
            const SizedBox(height: 22),
            const Text(
              'Ajustes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                ListTile(
                  tileColor: colores.superficie.withValues(alpha: 0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  key: const Key('perfil-beneficios'),
                  leading: Icon(
                    Icons.card_giftcard_outlined,
                    color: colores.primario,
                  ),
                  title: const Text('Beneficios'),
                  subtitle: const Text(
                    'Canjea tus Rebin Points por descuentos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BeneficiosScreen(repositorio: beneficiosPorDefecto()),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: colores.superficie.withValues(alpha: 0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  key: const Key('perfil-guia'),
                  leading: Icon(
                    Icons.menu_book_outlined,
                    color: colores.primario,
                  ),
                  title: const Text('Guía de reciclaje'),
                  subtitle: const Text('Qué sí y qué no va en cada contenedor'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GuiaReciclajeScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: colores.superficie.withValues(alpha: 0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  key: const Key('perfil-retos'),
                  leading: Icon(
                    Icons.emoji_events_outlined,
                    color: colores.primario,
                  ),
                  title: const Text('Retos'),
                  subtitle: const Text('Misiones de la semana y logros'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RetosScreen(repositorio: retosPorDefecto()),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: colores.superficie.withValues(alpha: 0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  key: const Key('perfil-para-reclamar'),
                  leading: Icon(
                    Icons.card_giftcard,
                    color: colores.recompensaTexto,
                  ),
                  title: const Text('Para reclamar'),
                  subtitle: const Text(
                    'Insignias, misiones y la sorpresa de hoy',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ParaReclamarScreen(
                        retos: retosPorDefecto(),
                        gamificacion: gamificacionPorDefecto(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  tileColor: colores.superficie.withValues(alpha: 0.78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  key: const Key('perfil-mis-reportes'),
                  leading: Icon(Icons.flag_outlined, color: colores.primario),
                  title: const Text('Mis reportes'),
                  subtitle: const Text('Cómo van los avisos que enviaste'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MisReportesScreen(repositorio: accionesPorDefecto()),
                    ),
                  ),
                ),
                const PermisosAjustes(),
              ],
            ),
            const SizedBox(height: 22),
            if (usuario != null && !usuario.esInvitado) ...[
              _CuentaCard(usuario: usuario),
              const SizedBox(height: 12),
            ],
            // Fuera del `if`: aunque el usuario no cargue (sin conexión o
            // RLS), siempre se puede iniciar sesión.
            _SesionCard(usuario: usuario),
            const SizedBox(height: 22),
            const Text(
              'Actividad reciente',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (perfil != null && perfil.actividad.isEmpty)
              Text(
                'Aún no tienes actividad. ¡Escanea o recicla tu primer objeto!',
                style: TextStyle(color: colores.textoSecundario),
              ),
            for (final actividad in perfil?.actividad ?? const [])
              ActividadPuntosTile(actividad: actividad),
          ],
        ),
      ),
    );
  }
}

/// Nivel y progreso de la cuenta, como en el rediseño: número y nombre del
/// nivel, saldo, barra hacia el siguiente y la escalera de los cinco niveles.
/// Los puntos y los umbrales vienen de Supabase; sin conexión se muestra la
/// última copia guardada, avisando de cuándo es.
class _NivelCard extends StatelessWidget {
  final ResumenPuntos resumen;
  final bool desdeCopia;
  final VoidCallback onReintentar;

  const _NivelCard({
    required this.resumen,
    required this.desdeCopia,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final niveles = [
      ...(resumen.niveles.isEmpty ? Nivel.porDefecto : resumen.niveles),
    ]..sort((a, b) => a.puntosMinimos - b.puntosMinimos);
    final actual = resumen.nivelActual;
    final siguiente = resumen.siguienteNivel;
    final acumulado = resumen.acumulado;
    // El saldo nunca se muestra negativo (los canjes lo descuentan).
    final saldo = resumen.saldo < 0 ? 0 : resumen.saldo;
    final estiloSecundario = TextStyle(
      color: colores.textoSecundario,
      fontSize: 12,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    actual.nombreCorto,
                    key: const Key('perfil-nivel-nombre'),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                Semantics(
                  label: 'Saldo para canjear: $saldo Rebin Points',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      IconoBonsai(
                        key: const Key('perfil-bonsai'),
                        size: 28,
                        color: colores.primario,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$saldo',
                        key: const Key('perfil-saldo'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          fontFeatures: Tipografia.cifras,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: resumen.progresoNivel,
                minHeight: 10,
                backgroundColor: colores.primarioSuave,
                valueColor: AlwaysStoppedAnimation(colores.primario),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    siguiente != null
                        ? 'Te faltan ${siguiente.puntosMinimos - acumulado} '
                              'Rebin Points para ${siguiente.nombreCorto}'
                        : 'Llegaste al nivel más alto',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  siguiente != null
                      ? '$acumulado / ${siguiente.puntosMinimos}'
                      : '$acumulado',
                  key: const Key('perfil-nivel-avance'),
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontFeatures: Tipografia.cifras,
                  ),
                ),
              ],
            ),
            if (desdeCopia) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 16,
                    color: colores.textoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sin conexión · datos del ${_fecha(resumen.actualizado)}',
                      style: estiloSecundario,
                    ),
                  ),
                  TextButton(
                    onPressed: onReintentar,
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: colores.borde),
            ),
            _EscaleraNiveles(niveles: niveles, acumulado: acumulado),
          ],
        ),
      ),
    );
  }

  static String _fecha(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)} a las ${dos(f.hour)}:${dos(f.minute)}';
  }
}

/// Los niveles de la tabla `niveles` con sus umbrales: alcanzados en verde, el
/// actual con un halo y los que faltan en verde suave.
class _EscaleraNiveles extends StatelessWidget {
  final List<Nivel> niveles;
  final int acumulado;

  const _EscaleraNiveles({required this.niveles, required this.acumulado});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final actual = Nivel.paraPuntos(acumulado, niveles);
    return Row(
      key: const Key('perfil-escalera'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in niveles)
          Expanded(
            child: Builder(
              builder: (context) {
                final esActual = n.puntosMinimos == actual.puntosMinimos;
                final alcanzado = acumulado >= n.puntosMinimos;
                return Semantics(
                  label:
                      '${n.nombreCorto}, ${n.puntosMinimos} Rebin Points, '
                      '${esActual
                          ? 'tu nivel'
                          : alcanzado
                          ? 'alcanzado'
                          : 'por alcanzar'}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: Container(
                            width: esActual ? 22 : 12,
                            height: esActual ? 22 : 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: esActual
                                  ? colores.primarioSuave
                                  : alcanzado
                                  ? colores.primario
                                  : colores.primarioSuave,
                            ),
                            child: esActual
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colores.primario,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Con letra grande el nombre se achica entero en vez
                      // de partirse a la mitad ("Nova-to").
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          n.nombreCorto,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: esActual
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: esActual ? null : colores.textoSecundario,
                          ),
                        ),
                      ),
                      Text(
                        '${n.puntosMinimos}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colores.textoSecundario,
                          fontFeatures: Tipografia.cifras,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Ocupa el lugar de la tarjeta de nivel mientras llegan los puntos desde
/// Supabase, o si fallaron (sin conexión, login anónimo deshabilitado, etc.).
class _NivelPendiente extends StatelessWidget {
  final bool error;
  final VoidCallback onReintentar;

  const _NivelPendiente({required this.error, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: error
            ? Row(
                children: [
                  Icon(Icons.wifi_off_outlined, color: colores.textoSecundario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No pudimos cargar tus Rebin Points.',
                      style: TextStyle(color: colores.textoSecundario),
                    ),
                  ),
                  TextButton(
                    onPressed: onReintentar,
                    child: const Text('Reintentar'),
                  ),
                ],
              )
            : const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
      ),
    );
  }
}

/// Las cifras del Perfil lado a lado; con letra grande (más de 130 %)
/// van una bajo otra, para que "reciclados" no se parta a la mitad.
class _Cifras extends StatelessWidget {
  final List<(Key, String, String)> cifras;

  const _Cifras({required this.cifras});

  @override
  Widget build(BuildContext context) {
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final cajas = [
      for (final (clave, numero, etiqueta) in cifras)
        _StatBox(key: clave, numero: numero, etiqueta: etiqueta),
    ];
    if (grande) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in cajas.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            c,
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in cajas.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: c),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String numero;
  final String etiqueta;

  const _StatBox({super.key, required this.numero, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colores.superficie.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xCCFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1E2B22),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            numero,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontFeatures: Tipografia.cifras),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(color: colores.textoSecundario, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Las insignias del Perfil son los logros reales: primero los conseguidos
/// (por nivel) y después los más avanzados. "Ver todas" abre Retos en Logros.
class _InsigniasPerfil extends StatefulWidget {
  final RetosRepository repositorio;

  const _InsigniasPerfil({required this.repositorio});

  @override
  State<_InsigniasPerfil> createState() => _InsigniasPerfilState();
}

class _InsigniasPerfilState extends State<_InsigniasPerfil> {
  static const _cuantas = 4;

  late Future<Retos> _futuro = widget.repositorio.retos();

  void _recargar() => setState(() => _futuro = widget.repositorio.retos());

  Future<void> _verTodas() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RetosScreen(repositorio: widget.repositorio, pestanaInicial: 1),
      ),
    );
    // Al volver puede haber reclamado un nivel.
    if (mounted) _recargar();
  }

  static List<Logro> _destacadas(List<Logro> logros) {
    final orden = [...logros]
      ..sort((a, b) {
        final porNivel = b.nivel.compareTo(a.nivel);
        return porNivel != 0 ? porNivel : b.progreso.compareTo(a.progreso);
      });
    return orden.take(_cuantas).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Insignias',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            TextButton(
              key: const Key('perfil-ver-insignias'),
              onPressed: _verTodas,
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FutureBuilder<Retos>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done && !snap.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'No pudimos cargar tus insignias.',
                      style: TextStyle(color: colores.textoSecundario),
                    ),
                  ),
                  TextButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final logros = _destacadas(snap.data!.logros);
            if (logros.isEmpty) {
              return Text(
                'Aún no hay insignias disponibles.',
                style: TextStyle(color: colores.textoSecundario),
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, l) in logros.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _InsigniaCard(logro: l, onTap: _verTodas),
                    ),
                  ],
                  // Con menos de 4 logros, las tarjetas no se estiran.
                  for (var i = logros.length; i < _cuantas; i++) ...[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Un logro como insignia: a color con anillo dorado si ya tiene un nivel,
/// atenuado si no; debajo, cuánto le falta o si hay un nivel por reclamar.
class _InsigniaCard extends StatelessWidget {
  final Logro logro;
  final VoidCallback onTap;

  const _InsigniaCard({required this.logro, required this.onTap});

  static const _romanos = ['I', 'II', 'III', 'IV', 'V'];

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final l = logro;
    final obtenida = l.nivel > 0;
    final titulo = obtenida ? '${l.nombre} ${_romanos[l.nivel - 1]}' : l.nombre;
    final (detalle, colorDetalle) = l.reclamable
        ? ('¡Por reclamar!', colores.recompensaTexto)
        : l.completo
        ? ('Completa', colores.primarioTexto)
        : ('Lleva ${l.metaActual - l.actual} más', colores.textoSecundario);
    final oscuro =
        ThemeData.estimateBrightnessForColor(l.color) == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Insignia $titulo. $detalle',
      excludeSemantics: true,
      child: Material(
        color: colores.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colores.borde),
        ),
        child: InkWell(
          key: Key('perfil-insignia-${l.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: obtenida ? l.color : null,
                    border: Border.all(
                      color: obtenida
                          ? colores.recompensa
                          : colores.textoSecundario,
                      width: obtenida ? 3 : 1.5,
                    ),
                  ),
                  child: Icon(
                    l.icono,
                    size: 22,
                    color: !obtenida
                        ? colores.textoSecundario
                        : oscuro
                        ? Colors.white
                        : const Color(0xFF1E2B22),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorDetalle, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Atajos del rediseño: Modo Eco (el selector completo sigue en Tema),
/// recordatorio amable de la racha (solo se guarda; aún no hay avisos) y
/// vibración.
class _Preferencias extends StatefulWidget {
  const _Preferencias();

  @override
  State<_Preferencias> createState() => _PreferenciasState();
}

class _PreferenciasState extends State<_Preferencias> {
  bool _recordatorio = true;
  bool _vibracion = Haptica.activa;

  @override
  void initState() {
    super.initState();
    RecordatorioRachaStore.leer().then((v) {
      if (mounted) setState(() => _recordatorio = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final tema = TemaScope.of(context);
    final subtitulo = TextStyle(color: colores.textoSecundario, fontSize: 12);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('perfil-modo-eco'),
            title: const Text('Modo Eco'),
            subtitle: Text('Colores de bosque, menos brillo', style: subtitulo),
            value: tema.tema == TemaApp.eco,
            onChanged: (v) => tema.cambiar(v ? TemaApp.eco : TemaApp.claro),
          ),
          Divider(height: 1, color: colores.borde),
          SwitchListTile(
            key: const Key('perfil-recordatorio'),
            title: const Text('Recordatorio amable'),
            subtitle: Text(
              'Un aviso a las 19:00 si tu racha corre riesgo. Pronto: aún no '
              'enviamos avisos.',
              style: subtitulo,
            ),
            value: _recordatorio,
            onChanged: (v) {
              setState(() => _recordatorio = v);
              RecordatorioRachaStore.guardar(v);
            },
          ),
          Divider(height: 1, color: colores.borde),
          SwitchListTile(
            key: const Key('perfil-vibracion'),
            title: const Text('Vibración'),
            subtitle: Text(
              'Al reclamar recompensas y subir de nivel',
              style: subtitulo,
            ),
            value: _vibracion,
            onChanged: (v) {
              setState(() => _vibracion = v);
              Haptica.guardar(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Estado de la cuenta: invitado (invita a crear cuenta), correo verificado
/// sin contraseña (retoma el registro) o cuenta completa. Iniciar y cerrar
/// sesión están en _SesionCard.
class _CuentaCard extends StatelessWidget {
  final Usuario usuario;

  const _CuentaCard({required this.usuario});

  Future<void> _abrir(BuildContext context, Widget pantalla, String ok) async {
    final listo = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => pantalla));
    if (listo == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final completa = !usuario.esInvitado && usuario.tieneContrasena;
    final (titulo, subtitulo, onTap) = usuario.esInvitado
        ? (
            'Crea una cuenta',
            'Guarda tu progreso y entra desde otro dispositivo',
            () => _abrir(
              context,
              const RegistroCuentaScreen(),
              '¡Listo! Tu cuenta quedó creada',
            ),
          )
        : !usuario.tieneContrasena
        ? (
            'Termina tu registro',
            'Crea la contraseña de ${usuario.correo}',
            () => _abrir(
              context,
              const RegistroCuentaScreen(pasoInicial: 2),
              '¡Listo! Tu cuenta quedó creada',
            ),
          )
        : ('Cuenta vinculada', usuario.correo!, null);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colores.fondoSecundario,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colores.secundario,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(color: colores.secundario, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              completa ? Icons.verified_outlined : Icons.arrow_forward,
              color: colores.secundario,
            ),
          ],
        ),
      ),
    );
  }
}

/// Iniciar y cerrar sesión. Se muestra siempre. Cerrar sesión solo actúa
/// con una cuenta con correo vinculado: a un invitado le explica por qué
/// está deshabilitado (no tendría cómo volver a entrar y perdería sus
/// puntos).
class _SesionCard extends StatelessWidget {
  final Usuario? usuario;

  const _SesionCard({required this.usuario});

  CuentaRepository _repositorio() => SupabaseService.disponible
      ? CuentaRepositorySupabase()
      : CuentaRepositoryMock(conCorreo: !(usuario?.esInvitado ?? true));

  Future<void> _iniciarSesion(BuildContext context) async {
    // Se toma antes: al cambiar de cuenta el MainShell (y este Perfil) se
    // reconstruye, pero el ScaffoldMessenger de la app sigue.
    final avisos = ScaffoldMessenger.of(context);
    final mensaje = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const IniciarSesionScreen()),
    );
    if (mensaje != null) {
      avisos.showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _cerrarSesion(
    BuildContext context,
    CuentaRepository repo,
  ) async {
    if (!repo.tieneCorreoVinculado) {
      await showDialog<void>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            'Esta sesión no tiene un correo vinculado, por lo tanto esta '
            'acción está deshabilitada. Podrás cerrar sesión cuando entres a '
            'una cuenta con correo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Volverás a entrar como invitado. Tus puntos quedan guardados en tu '
          'cuenta y los vuelves a ver al iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final avisos = ScaffoldMessenger.of(context);
    final usuarioCtrl = UsuarioScope.of(context);
    final perfilLocal = PerfilLocalScope.of(context);
    try {
      // Los datos de la cuenta quedan en Supabase. Se sigue como invitado
      // sin pasar por la bienvenida ni pedir permisos: al cambiar la clave
      // del perfil local el MainShell se reconstruye y vuelve a Inicio.
      final idInvitado = await repo.cerrarSesion();
      await perfilLocal.cambiarClave(idInvitado);
      await usuarioCtrl.cargar();
      avisos.showSnackBar(const SnackBar(content: Text('Cerraste sesión')));
    } on CuentaException catch (e) {
      debugPrint('CerrarSesion: $e');
      avisos.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final repo = _repositorio();
    final puedeCerrar = repo.tieneCorreoVinculado;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.login, color: colores.primario),
            title: const Text('Iniciar sesión'),
            subtitle: const Text('Entra con tu correo y contraseña'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _iniciarSesion(context),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: puedeCerrar ? colores.primario : colores.textoSecundario,
            ),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: puedeCerrar ? null : colores.textoSecundario,
              ),
            ),
            subtitle: Text(
              puedeCerrar
                  ? (usuario?.correo ?? 'Cuenta con correo')
                  : 'Disponible con una cuenta con correo vinculado',
            ),
            onTap: () => _cerrarSesion(context, repo),
          ),
        ],
      ),
    );
  }
}
