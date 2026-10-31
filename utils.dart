/// Année scolaire par défaut : à partir de septembre, "AAAA-AAAA+1".
String anneeScolaireParDefaut([DateTime? now]) {
  final d = now ?? DateTime.now();
  final debut = d.month >= 9 ? d.year : d.year - 1;
  return '$debut-${debut + 1}';
}

/// "2012-03-25" -> "25/03/2012"
String formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// DateTime -> "AAAA-MM-JJ" (format stocké en base)
String toIsoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int? calculerAge(String? iso, [DateTime? now]) {
  if (iso == null || iso.isEmpty) return null;
  final n = DateTime.tryParse(iso);
  if (n == null) return null;
  final today = now ?? DateTime.now();
  var age = today.year - n.year;
  if (today.month < n.month || (today.month == n.month && today.day < n.day)) {
    age--;
  }
  return age < 0 ? null : age;
}

/// "kaboré jean-paul" -> "Kaboré Jean-Paul"
String capitaliserMots(String s) {
  return s.trim().toLowerCase().replaceAllMapped(
        RegExp(r'(^|[\s\-])(\S)'),
        (m) => '${m[1]}${m[2]!.toUpperCase()}',
      );
}

String? nullSiVide(String? s) {
  final t = s?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// 2 -> "2 h", 1.5 -> "1,5 h"
String formatHeures(double h) {
  final txt = h == h.roundToDouble()
      ? h.toInt().toString()
      : h.toString().replaceAll('.', ',');
  return '$txt h';
}
