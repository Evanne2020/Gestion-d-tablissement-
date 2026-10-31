import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../core/utils.dart';
import '../models/eleve.dart';
import 'rapport_base.dart';

/// Liste des élèves en PDF : une page (ou plus) par classe,
/// triée par ordre alphabétique.
class ListeElevesPdf {
  static const titre = 'Liste des élèves';

  /// [eleves] : élèves déjà filtrés et triés (voir EleveRepository.rechercher).
  /// [classeNom] : nom de la classe choisie (sert pour le cas « aucun élève »).
  static Future<Uint8List> generer({
    required RapportBase base,
    required List<Eleve> eleves,
    String? classeNom,
  }) async {
    final doc = base.nouveauDocument(titre);

    if (eleves.isEmpty) {
      doc.addPage(base.page(
        titre: titre,
        sousTitres: [if (classeNom != null) 'Classe : $classeNom'],
        contenu: (_) => [pw.Text('Aucun élève à afficher.')],
      ));
      return doc.save();
    }

    // Regroupement par classe, classes dans l'ordre alphabétique.
    final groupes = <int, List<Eleve>>{};
    for (final e in eleves) {
      groupes.putIfAbsent(e.classeId, () => []).add(e);
    }
    String nomDe(int id) => (groupes[id]!.first.classeNom ?? '').toLowerCase();
    final ordre = groupes.keys.toList()..sort((a, b) => nomDe(a).compareTo(nomDe(b)));

    for (final id in ordre) {
      final liste = groupes[id]!;
      final nom = liste.first.classeNom ?? '';
      final filles = liste.where((e) => e.sexe == 'F').length;
      final garcons = liste.length - filles;

      doc.addPage(base.page(
        titre: titre,
        sousTitres: [
          'Classe : $nom',
          'Effectif : ${liste.length} élève(s) — $filles fille(s), $garcons garçon(s)',
        ],
        contenu: (_) => [
          base.tableau(
            entetes: const [
              'N°',
              'Matricule',
              'Nom et prénoms',
              'Sexe',
              'Né(e) le',
              'Parent',
              'Tél. parent',
            ],
            lignes: [
              for (var i = 0; i < liste.length; i++)
                [
                  '${i + 1}',
                  liste[i].matricule ?? '',
                  liste[i].nomComplet,
                  liste[i].sexe,
                  liste[i].dateNaissance == null
                      ? ''
                      : formatDateFr(liste[i].dateNaissance),
                  liste[i].nomParent ?? '',
                  liste[i].telephoneParent ?? '',
                ],
            ],
            largeurs: const {
              0: pw.FixedColumnWidth(24),
              1: pw.FixedColumnWidth(62),
              2: pw.FlexColumnWidth(3),
              3: pw.FixedColumnWidth(30),
              4: pw.FixedColumnWidth(62),
              5: pw.FlexColumnWidth(2),
              6: pw.FixedColumnWidth(72),
            },
            alignements: const {
              0: pw.TextAlign.center,
              3: pw.TextAlign.center,
              4: pw.TextAlign.center,
            },
          ),
        ],
      ));
    }
    return doc.save();
  }
}
