import 'package:flutter_test/flutter_test.dart';
import 'package:gest_etab/reports/rapport_base.dart';

void main() {
  final jour = DateTime(2026, 10, 31);

  test('nom de fichier sans accents ni caractères spéciaux', () {
    expect(
      RapportBase.nomFichier('liste_eleves',
          classeNom: '6e A — Éveil', maintenant: jour),
      'liste_eleves_6e_a_eveil_2026-10-31.pdf',
    );
  });

  test('toutes les classes', () {
    expect(
      RapportBase.nomFichier('liste_eleves', maintenant: jour),
      'liste_eleves_toutes_classes_2026-10-31.pdf',
    );
  });
}
