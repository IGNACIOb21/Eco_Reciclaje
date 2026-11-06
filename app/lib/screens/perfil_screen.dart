import 'package:flutter/material.dart';

import '../models/insignia.dart';
import '../models/nivel.dart';
import '../models/perfil_usuario.dart';
import '../models/usuario.dart';
import '../state/perfil_local_controller.dart';
import '../state/usuario_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/actividad_puntos_tile.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/permisos_ajustes.dart';
import 'iniciar_sesion_screen.dart';
import 'personalizar_perfil_sheet.dart';
import 'registro_cuenta_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => mostrarPersonalizarPerfil(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AvatarUsuario(
                      icono: local.avatarIcono,
                      color: local.avatarColor,
                      tamano: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            local.nombreVisible,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            perfil == null
                                ? local.comuna
                                : 'Reciclando desde ${perfil.miembroDesde} · ${local.comuna}',
                            style: TextStyle(
                              color: colores.textoSecundario,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, color: colores.textoSecundario),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (perfil != null)
              _NivelCard(perfil: perfil)
            else
              _NivelPendiente(
                error: usuarioCtrl.error != null && !usuarioCtrl.cargando,
                onReintentar: usuarioCtrl.cargar,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    numero: '${perfil?.objetosEscaneados ?? "–"}',
                    etiqueta: 'Objetos escaneados',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    numero: '${perfil?.reportesHechos ?? "–"}',
                    etiqueta: 'Reportes hechos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Insignias',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final insignia
                    in perfil?.insignias ?? const <Insignia>[]) ...[
                  _InsigniaBadge(insignia: insignia),
                  const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Ajustes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: colores.primario,
                    ),
                    title: const Text('Personalizar perfil'),
                    subtitle: const Text('Nombre visible, ícono y comuna'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => mostrarPersonalizarPerfil(context),
                  ),
                  Divider(height: 1, color: colores.borde),
                  SwitchListTile(
                    secondary: Icon(
                      Icons.eco_outlined,
                      color: colores.primario,
                    ),
                    title: const Text('Modo Eco'),
                    subtitle: const Text('Tema tierra y verde profundo'),
                    value: local.modoEco,
                    onChanged: (valor) =>
                        controller.actualizar(local.copyWith(modoEco: valor)),
                  ),
                  const PermisosAjustes(),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (usuario != null) ...[
              _CuentaCard(usuario: usuario),
              const SizedBox(height: 22),
            ],
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

class _NivelCard extends StatelessWidget {
  final PerfilUsuario perfil;

  const _NivelCard({required this.perfil});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final tope = perfil.puntosParaSiguienteNivel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nivel ${perfil.nivelActual.etiqueta}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  tope != null
                      ? '${perfil.puntosTotales}/$tope pts'
                      : '${perfil.puntosTotales} pts',
                  style: TextStyle(
                    color: colores.textoSecundario,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: perfil.progresoNivel,
                minHeight: 8,
                backgroundColor: colores.superficieAlta,
                valueColor: AlwaysStoppedAnimation(colores.primario),
              ),
            ),
            if (tope != null) ...[
              const SizedBox(height: 8),
              Text(
                '${tope - perfil.puntosTotales} pts para Nivel ${perfil.nivelActual.siguiente!.etiqueta}',
                style: TextStyle(color: colores.textoSecundario, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
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
                      'No pudimos cargar tus puntos.',
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

class _StatBox extends StatelessWidget {
  final String numero;
  final String etiqueta;

  const _StatBox({required this.numero, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colores.superficieAlta,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            numero,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 4),
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

class _InsigniaBadge extends StatelessWidget {
  final Insignia insignia;

  const _InsigniaBadge({required this.insignia});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: insignia.obtenida
            ? insignia.color.withValues(alpha: 0.18)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: insignia.obtenida
            ? null
            : Border.all(color: colores.borde, width: 1.5),
      ),
      child: Icon(
        insignia.icono,
        color: insignia.obtenida ? insignia.color : colores.textoSecundario,
      ),
    );
  }
}

/// Estado de la cuenta: invitado (invita a crear cuenta o iniciar sesión),
/// correo verificado sin contraseña (retoma el registro) o cuenta completa.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
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
                        style: TextStyle(
                          color: colores.secundario,
                          fontSize: 12,
                        ),
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
        ),
        if (usuario.esInvitado)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _abrir(
                context,
                const IniciarSesionScreen(),
                'Sesión iniciada',
              ),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ),
      ],
    );
  }
}
