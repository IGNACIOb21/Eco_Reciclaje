import 'package:flutter/material.dart';

import '../services/permisos_service.dart';
import '../theme/app_theme.dart';

/// Filas de Ajustes del Perfil con el estado de los permisos de ubicación y
/// notificaciones, para activarlos si se rechazaron en la bienvenida. Vuelve
/// a leer el estado al regresar a la app (ej. desde los ajustes del teléfono).
class PermisosAjustes extends StatefulWidget {
  final PermisosService permisos;

  const PermisosAjustes({super.key, this.permisos = const PermisosService()});

  @override
  State<PermisosAjustes> createState() => _PermisosAjustesState();
}

class _PermisosAjustesState extends State<PermisosAjustes>
    with WidgetsBindingObserver {
  final Map<PermisoApp, EstadoPermiso> _estados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refrescar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refrescar();
  }

  Future<void> _refrescar() async {
    for (final p in PermisoApp.values) {
      final estado = await widget.permisos.estado(p);
      if (!mounted) return;
      setState(() => _estados[p] = estado);
    }
  }

  Future<void> _pedir(PermisoApp p) async {
    final estado = await widget.permisos.pedir(p);
    if (mounted) setState(() => _estados[p] = estado);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Column(
      children: [
        for (final p in PermisoApp.values) ...[
          Divider(height: 1, color: colores.borde),
          _fila(context, p),
        ],
      ],
    );
  }

  Widget _fila(BuildContext context, PermisoApp p) {
    final colores = context.colores;
    final estado = _estados[p];
    final concedido = estado == EstadoPermiso.concedido;
    final (icono, titulo, siConcedido, siNo) = switch (p) {
      PermisoApp.ubicacion => (
        Icons.my_location,
        'Ubicación',
        'Activa: el mapa te sigue en tiempo real',
        'Desactivada: el mapa no puede ubicarte',
      ),
      PermisoApp.notificaciones => (
        Icons.notifications_outlined,
        'Notificaciones',
        'Activadas',
        'Desactivadas: no recibirás avisos',
      ),
    };
    return ListTile(
      leading: Icon(icono, color: colores.primario),
      title: Text(titulo),
      subtitle: Text(
        estado == null ? 'Revisando…' : (concedido ? siConcedido : siNo),
      ),
      trailing: estado == null || concedido
          ? (concedido ? Icon(Icons.check, color: colores.primario) : null)
          : TextButton(
              onPressed: () => _pedir(p),
              child: Text(
                estado == EstadoPermiso.bloqueado ? 'Ajustes' : 'Activar',
              ),
            ),
      onTap: concedido || estado == null ? null : () => _pedir(p),
    );
  }
}
