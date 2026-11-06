import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Shape compartido por los bottom sheets de la app: esquinas superiores
/// redondeadas con [AppRadius.sheet].
const appBottomSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
);

/// Abre un bottom sheet con el shape y el scroll control ya configurados.
Future<T?> mostrarAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    shape: appBottomSheetShape,
    builder: builder,
  );
}

/// Contenido común de un bottom sheet: `SafeArea` + padding + handle arriba,
/// scrolleable, con [child] debajo.
class AppBottomSheet extends StatelessWidget {
  final Widget child;

  const AppBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colores.borde,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
