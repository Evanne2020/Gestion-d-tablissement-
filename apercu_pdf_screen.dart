import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

void afficherMessage(BuildContext context, String message, {bool erreur = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: erreur ? Colors.red : null),
  );
}

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
      afficherMessage(context, 'Impression impossible sur cet appareil.', erreur: true);
    }
  }

  Future<void> _partager(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: octets, filename: nomFichier);
    } catch (_) {
      if (!context.mounted) return;
      afficherMessage(context, 'Partage impossible. Utilisez « Enregistrer ».', erreur: true);
    }
  }

  Future<void> _enregistrer(BuildContext context) async {
    try {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le PDF',
        fileName: nomFichier,
        bytes: octets,
      );
      if (!context.mounted) return;
      afficherMessage(context, 'PDF enregistré avec succès.');
    } catch (_) {
      if (!context.mounted) return;
      afficherMessage(context, 'Enregistrement impossible.', erreur: true}
                          }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        actions: [
          IconButton(icon: const Icon(Icons.print), onPressed: () => _imprimer(context)),
          if (_partageDisponible)
            IconButton(icon: const Icon(Icons.share), onPressed: () => _partager(context)),
          IconButton(icon: const Icon(Icons.save_alt), onPressed: () => _enregistrer(context)),
        ],
      ),
      body: PdfPreview(
        build: (format) => octets,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
                      }
