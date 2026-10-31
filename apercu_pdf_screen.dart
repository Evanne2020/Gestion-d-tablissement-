import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/ui.dart';

/// Aperçu d'un PDF généré, avec Imprimer, Partager et Enregistrer.
/// Fonctionne hors ligne.
class ApercuPdfScreen extends StatelessWidget {
  final String titre;
  final String nomFichier;
  final Uint8List octets;

  const ApercuPdfScreen({
    super.key,
    required this.titre,
    required this.nomFichier,
    required this.octets,
  });

  bool get _partageDisponible =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get _bureau =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _imprimer(BuildContext context) async {
    try {
      await Printing.layoutPdf(onLayout: (_) async => octets, name: nomFichier);
    } catch (_) {
      if (!context.mounted) return;
      afficherMessage(context, 'Impression impossible sur cet appareil.',
          erreur: true);
    }
  }

  Future<void> _partager(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: octets, filename: nomFichier);
    } catch (_) {
      if (!context.mounted) return;
      afficherMessage(context, 'Partage impossible. Utilisez « Enregistrer ».',
          erreur: true);
    }
  }

  Future<void> _enregistrer(BuildContext context) async {
    try {
      final chemin = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le PDF',
        fileName: nomFichier,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: octets,
      );
      if (chemin == null) return; // annulé par l'utilisateur
      if (_bureau) {
        // Sur ordinateur, on écrit le fichier nous-mêmes (sans effet néfaste
        // si le sélecteur l'a déjà écrit : mêmes octets).
        final fin = chemin.toLowerCase().endsWith('.pdf') ? chemin : '$chemin.pdf';
        await File(fin).writeAsBytes(octets);
        if (!context.mounted) return;
        afficherMessage(context, 'PDF enregistré : $fin');
      } else {
        if (!context.mounted) return;
        afficherMessage(context, 'PDF enregistré.');
      }
    } catch (_) {
      if (!context.mounted) return;
      afficherMessage(context, 'L\'enregistrement a échoué.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (_) => octets,
              useActions: false,
              pdfFileName: nomFichier,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _imprimer(context),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Imprimer'),
                    ),
                  ),
                  if (_partageDisponible) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _partager(context),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Partager'),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _enregistrer(context),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
