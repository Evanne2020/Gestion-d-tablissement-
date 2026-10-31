import 'package:flutter_test/flutter_test.dart';
import 'package:gest_etab/core/utils.dart';

void main() {
  test('année scolaire par défaut', () {
    expect(anneeScolaireParDefaut(DateTime(2026, 10, 31)), '2026-2027');
    expect(anneeScolaireParDefaut(DateTime(2027, 3, 1)), '2026-2027');
  });

  test('formats de date', () {
    expect(formatDateFr('2012-03-05'), '05/03/2012');
    expect(formatDateFr(null), '—');
    expect(toIsoDate(DateTime(2012, 3, 5)), '2012-03-05');
  });

  test('calcul de l\'âge', () {
    expect(calculerAge('2010-06-15', DateTime(2026, 6, 14)), 15);
    expect(calculerAge('2010-06-15', DateTime(2026, 6, 15)), 16);
    expect(calculerAge(null), isNull);
  });

  test('capitalisation des prénoms', () {
    expect(capitaliserMots('kaboré jean-paul'), 'Kaboré Jean-Paul');
  });
}
