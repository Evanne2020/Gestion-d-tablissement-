import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils.dart';

/// Éléments communs à tous les rapports PDF : polices (embarquées, donc
/// hors ligne), en-tête, pied de page et tableaux.
class RapportBase {
  final pw.Font police;
  final pw.Font policeGras;
  final String nomEtablissement;
  final String anneeScolaire;
  final String dateEdition; // JJ/MM/AAAA

  const RapportBase({
    required this.police,
    required this.policeGras,
    required this.nomEtablissement,
    required this.anneeScolaire,
    required this.dateEdition,
  });

  static Future<RapportBase> charger({
    required String nomEtablissement,
    required String anneeScolaire,
    DateTime? maintenant,
  }) async {
    final regulier =
        await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf');
    final gras = await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf');
    final n = maintenant ?? DateTime.now();
    return RapportBase(
      police: pw.Font.ttf(regulier),
      policeGras: pw.Font.ttf(gras),
      nomEtablissement: nomEtablissement,
      anneeScolaire: anneeScolaire,
      dateEdition: formatDateFr(toIsoDate(n)),
    );
  }

  /// Nom de fichier sûr : ex. liste_eleves_6e_a_2026-10-31.pdf
  static String nomFichier(String prefixe,
      {String? classeNom, DateTime? maintenant}) {
    final date = toIsoDate(maintenant ?? DateTime.now());
    final classe = classeNom == null ? 'toutes_classes' : _slug(classeNom);
    return '${prefixe}_${classe}_$date.pdf';
  }

  static String _slug(String s) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'ç': 'c',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'œ': 'oe',
    };
    var r = s.toLowerCase();
    accents.forEach((k, v) => r = r.replaceAll(k, v));
    r = r.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    r = r.replaceAll(RegExp(r'^_+|_+$'), '');
    return r.isEmpty ? 'classe' : r;
  }

  pw.Document nouveauDocument(String titre) => pw.Document(
        title: titre,
        author: nomEtablissement,
        creator: 'GEST-ÉTAB',
        theme: pw.ThemeData.withFont(
          base: police,
          bold: policeGras,
          italic: police,
          boldItalic: policeGras,
        ),
      );

  /// Page A4 (multi-pages) avec en-tête et pied de page standard.
  pw.MultiPage page({
    required String titre,
    List<String> sousTitres = const [],
    required List<pw.Widget> Function(pw.Context) contenu,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
      header: (ctx) => _enTete(titre, sousTitres),
      footer: _pied,
      build: contenu,
    );
  }

  pw.Widget _enTete(String titre, List<String> sousTitres) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                nomEtablissement.toUpperCase(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text('Année scolaire $anneeScolaire',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          titre,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        for (final s in sousTitres)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(s,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10)),
          ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.8, height: 8),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _pied(pw.Context ctx) {
    final style = const pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Édité le $dateEdition · GEST-ÉTAB', style: style),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: style),
        ],
      ),
    );
  }

  /// Tableau avec ligne d'en-tête répétée sur chaque page et lignes alternées.
  pw.Widget tableau({
    required List<String> entetes,
    required List<List<String>> lignes,
    required Map<int, pw.TableColumnWidth> largeurs,
    Map<int, pw.TextAlign> alignements = const {},
  }) {
    pw.Widget cellule(String texte, int col, {bool gras = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: pw.Text(
            texte,
            textAlign: alignements[col] ?? pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: gras ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      columnWidths: largeurs,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            for (var i = 0; i < entetes.length; i++)
              cellule(entetes[i], i, gras: true),
          ],
        ),
        for (var r = 0; r < lignes.length; r++)
          pw.TableRow(
            decoration: r.isOdd
                ? const pw.BoxDecoration(color: PdfColors.grey100)
                : null,
            children: [
              for (var c = 0; c < lignes[r].length; c++)
                cellule(lignes[r][c], c),
            ],
          ),
      ],
    );
  }
}
