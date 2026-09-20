import 'package:flutter/material.dart';

/// Se muestra cuando no se pudo consultar el servidor para restaurar el perfil
/// y el progreso de una cuenta existente (dispositivo nuevo o datos borrados).
///
/// NUNCA permite seguir como usuario nuevo: sin saber si la cuenta ya tiene
/// datos, crear un perfil vacío podría pisar los reales.
///
/// Devuelve true si el usuario quiere reintentar; false si cancela. Cerrarlo
/// con el botón Atrás o tocando fuera cuenta como cancelar.
Future<bool> mostrarDialogoRestauracionFallida(BuildContext context) async {
  final reintentar = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false, // Atrás = cancelar (nunca continuar como usuario nuevo)
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(ctx).pop(false);
      },
      child: AlertDialog(
        title: const Text('No pudimos recuperar tu progreso'),
        content: const Text(
          'No hay conexión con el servidor. Conéctate a internet e inténtalo '
          'de nuevo para recuperar tu progreso y tu perfil.\n\n'
          'Tu progreso está a salvo: no se borra ni se reemplaza.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
  return reintentar ?? false;
}

/// Mensaje que se muestra al cancelar la restauración.
const String kMensajeRestauracionCancelada =
    'No pudimos recuperar tu progreso sin conexión. '
    'Inténtalo de nuevo cuando tengas internet.';
