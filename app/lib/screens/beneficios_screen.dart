import 'package:flutter/material.dart';

import '../models/beneficio.dart';
import '../models/mi_canje.dart';
import '../repositories/beneficios_repository.dart';
import '../state/usuario_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/snackbars.dart';
import 'mis_canjes_screen.dart';
import '../widgets/esqueleto.dart';

/// Catálogo de beneficios que las entidades ofrecen a cambio de puntos. Solo
/// una cuenta con correo puede canjear; el invitado ve el catálogo.
class BeneficiosScreen extends StatefulWidget {
  final BeneficiosRepository repositorio;

  const BeneficiosScreen({super.key, required this.repositorio});

  @override
  State<BeneficiosScreen> createState() => _BeneficiosScreenState();
}

class _BeneficiosScreenState extends State<BeneficiosScreen> {
  late Future<List<Beneficio>> _beneficios = widget.repositorio.beneficios();
  int? _canjeando;
  bool _saldoPedido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El saldo se actualiza al abrir la pantalla: puede haber cambiado en el
    // servidor desde la última carga (p. ej. un canje cancelado desde el panel).
    if (_saldoPedido) return;
    _saldoPedido = true;
    final controller = context
        .getInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller?.cargar());
  }

  void _recargar() {
    setState(() {
      _beneficios = widget.repositorio.beneficios();
    });
  }

  Future<void> _canjear(Beneficio b, UsuarioController? usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Canjear este beneficio?'),
        content: Text(
          '${b.nombre}\n\nSe descontarán ${b.costo} Rebin Points de tu saldo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('canje-confirmar'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _canjeando = b.id);
    try {
      final r = await widget.repositorio.canjear(b.id);
      usuario?.cargar();
      if (!mounted) return;
      // El indicador del botón se apaga antes de mostrar el código: si no,
      // sigue girando detrás del diálogo.
      setState(() => _canjeando = null);
      _recargar();
      await _mostrarCodigo(b, r);
    } on CanjeException catch (e) {
      if (!mounted) return;
      mostrarSnackbar(context, e.mensaje);
      // Si cambió el catálogo (se agotó, venció), se actualiza.
      if (e.motivo == MotivoErrorCanje.sinStock ||
          e.motivo == MotivoErrorCanje.beneficioNoDisponible ||
          e.motivo == MotivoErrorCanje.topeAlcanzado) {
        _recargar();
      }
    } catch (_) {
      if (mounted) {
        mostrarSnackbar(
          context,
          const CanjeException(MotivoErrorCanje.desconocido).mensaje,
        );
      }
    } finally {
      if (mounted) setState(() => _canjeando = null);
    }
  }

  Future<void> _mostrarCodigo(Beneficio b, ResultadoCanje r) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Canje listo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Muestra este código en ${b.entidad}:'),
            const SizedBox(height: 12),
            Center(
              child: SelectableText(
                r.codigo,
                key: const Key('canje-codigo'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Te quedan ${r.saldo} Rebin Points. Lo encuentras en "Mis canjes".',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final controller = context
        .dependOnInheritedWidgetOfExactType<UsuarioScope>()
        ?.notifier;
    final usuario = controller?.usuario;
    final saldo = usuario?.puntosTotales;
    final invitado = usuario?.esInvitado ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficios'),
        actions: [
          IconButton(
            key: const Key('beneficios-mis-canjes'),
            tooltip: 'Mis canjes',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MisCanjesScreen(repositorio: widget.repositorio),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Beneficio>>(
          future: _beneficios,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const EsqueletoLista();
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar los beneficios.'),
                    TextButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final lista = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (saldo != null)
                  Text(
                    'Tu saldo: $saldo Rebin Points',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                if (invitado) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Para canjear necesitas una cuenta con correo. Créala desde tu Perfil: conservas tus Rebin Points.',
                    style: TextStyle(color: colores.textoSecundario),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (lista.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Text(
                      'Por ahora no hay beneficios disponibles. Vuelve pronto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colores.textoSecundario),
                    ),
                  ),
                for (final b in lista)
                  _TarjetaBeneficio(
                    beneficio: b,
                    saldo: saldo,
                    invitado: invitado,
                    ocupado: _canjeando == b.id,
                    onCanjear: () => _canjear(b, controller),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaBeneficio extends StatelessWidget {
  final Beneficio beneficio;
  final int? saldo;
  final bool invitado;
  final bool ocupado;
  final VoidCallback onCanjear;

  const _TarjetaBeneficio({
    required this.beneficio,
    required this.saldo,
    required this.invitado,
    required this.ocupado,
    required this.onCanjear,
  });

  String get _textoBoton {
    if (beneficio.topeAlcanzado) return 'Ya lo canjeaste';
    if (invitado) return 'Necesitas una cuenta';
    final falta = saldo == null ? 0 : beneficio.costo - saldo!;
    if (falta > 0) return 'Te faltan $falta Rebin Points';
    return 'Canjear';
  }

  bool get _puedeCanjear =>
      !ocupado &&
      !invitado &&
      !beneficio.topeAlcanzado &&
      saldo != null &&
      saldo! >= beneficio.costo;

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final b = beneficio;
    final fin =
        '${b.vigenciaFin.day.toString().padLeft(2, '0')}/'
        '${b.vigenciaFin.month.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  b.esSorteo
                      ? Icons.casino_outlined
                      : Icons.local_offer_outlined,
                  color: colores.primario,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${b.costo} Rebin Points',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colores.acento,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(b.entidad, style: TextStyle(color: colores.textoSecundario)),
            if (b.descripcion != null && b.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(b.descripcion!),
            ],
            const SizedBox(height: 6),
            Text(
              [
                'Hasta el $fin',
                if (b.stock != null && b.stock! <= 10)
                  b.stock == 1 ? 'Queda 1' : 'Quedan ${b.stock}',
                if (b.tope != null) 'Máx. ${b.tope} por persona',
                if (b.esSorteo) 'Sorteo',
              ].join(' · '),
              style: TextStyle(color: colores.textoSecundario, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: Key('canjear-${b.id}'),
                onPressed: _puedeCanjear ? onCanjear : null,
                child: ocupado
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_textoBoton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
