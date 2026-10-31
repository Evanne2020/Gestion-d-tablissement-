import 'utils.dart';

enum TypePeriode { aujourdhui, semaine, mois, annee, personnalisee }

/// Intervalle de dates (bornes incluses) utilisé pour filtrer les listes.
class Periode {
  final TypePeriode type;
  final DateTime debut;
  final DateTime fin;
  const Periode(this.type, this.debut, this.fin);

  String get du => toIsoDate(debut);
  String get au => toIsoDate(fin);

  static String libelle(TypePeriode t) {
    switch (t) {
      case TypePeriode.aujourdhui:
        return 'Aujourd\'hui';
      case TypePeriode.semaine:
        return 'Cette semaine';
      case TypePeriode.mois:
        return 'Ce mois';
      case TypePeriode.annee:
        return 'Toute l\'année scolaire';
      case TypePeriode.personnalisee:
        return 'Dates personnalisées…';
    }
  }

  /// [annee] : ex. "2026-2027" (du 1er septembre au 31 août).
  static Periode calculer(
    TypePeriode type, {
    required String annee,
    DateTime? maintenant,
    DateTime? debutPerso,
    DateTime? finPerso,
  }) {
    final n = maintenant ?? DateTime.now();
    final jour = DateTime(n.year, n.month, n.day);
    switch (type) {
      case TypePeriode.aujourdhui:
        return Periode(type, jour, jour);
      case TypePeriode.semaine:
        final lundi = DateTime(jour.year, jour.month, jour.day - (jour.weekday - 1));
        final dimanche = DateTime(lundi.year, lundi.month, lundi.day + 6);
        return Periode(type, lundi, dimanche);
      case TypePeriode.mois:
        return Periode(type, DateTime(jour.year, jour.month, 1),
            DateTime(jour.year, jour.month + 1, 0));
      case TypePeriode.annee:
        final debut = annee.length >= 4 ? int.tryParse(annee.substring(0, 4)) : null;
        final y = debut ?? jour.year;
        return Periode(type, DateTime(y, 9, 1), DateTime(y + 1, 8, 31));
      case TypePeriode.personnalisee:
        final d = debutPerso ?? jour;
        final f = finPerso ?? d;
        return f.isBefore(d) ? Periode(type, f, d) : Periode(type, d, f);
    }
  }
}
