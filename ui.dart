import 'package:flutter/material.dart';

/// Message de confirmation (vert/neutre) ou d'erreur (rouge).
void afficherMessage(BuildContext context, String message,
    {bool erreur = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? cs.error : null,
    ));
}

/// Boîte de confirmation. Retourne true si l'utilisateur confirme.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String message,
  String libelleConfirmer = 'Supprimer',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titre),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(libelleConfirmer),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Centre le contenu et limite sa largeur (confort sur Windows/tablette).
Widget centrer(Widget child, {double maxWidth = 760}) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

/// F en rouge, M en bleu.
Color couleurSexe(String sexe) =>
    sexe == 'F' ? Colors.red.shade600 : Colors.blue.shade700;
