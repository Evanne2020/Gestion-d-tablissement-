import 'package:flutter_test/flutter_test.dart';
import 'package:gest_etab/core/periode.dart';
import 'package:gest_etab/core/utils.dart';

void main() {
  // Le 31 octobre 2026 est un samedi.
  final jour = DateTime(2026, 10, 31);

  test('semaine : du lundi au dimanche', () {
    final p = Periode.calculer(TypePeriode.semaine,
        annee: '2026-2027', maintenant: jour);
    expect(p.du, '2026-10-26');
    expect(p.au, '2026-11-01');
  });

  test('mois', () {
    final p = Periode.calculer(TypePeriode.mois,
        annee: '2026-2027', maintenant: jour);
    expect(p.du, '2026-10-01');
    expect(p.au, '2026-10-31');
  });

  test('année scolaire', () {
    final p = Periode.calculer(TypePeriode.annee,
        annee: '2026-2027', maintenant: jour);
    expect(p.du, '2026-09-01');
    expect(p.au, '2027-08-31');
  });

  test('dates personnalisées inversées sont remises dans l\'ordre', () {
    final p = Periode.calculer(TypePeriode.personnalisee,
        annee: '2026-2027',
        debutPerso: DateTime(2026, 11, 5),
        finPerso: DateTime(2026, 11, 1));
    expect(p.du, '2026-11-01');
    expect(p.au, '2026-11-05');
  });

  test('formatHeures', () {
    expect(formatHeures(2), '2 h');
    expect(formatHeures(1.5), '1,5 h');
  });
}
