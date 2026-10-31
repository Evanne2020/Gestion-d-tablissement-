import '../core/database/app_database.dart';
import '../models/presence.dart';

class PresenceRepository {
  static const _select = '''
    SELECT p.*, e.nom AS eleve_nom, e.prenoms AS eleve_prenoms,
           e.sexe AS eleve_sexe, e.classe_id AS classe_id, c.nom AS classe_nom
    FROM presences p
    JOIN eleves e ON e.id = p.eleve_id
    JOIN classes c ON c.id = e.classe_id
  ''';

  /// Absences et/ou retards de l'année scolaire, du plus récent au plus ancien.
  Future<List<Presence>> lister({
    required String annee,
    String? type,
    int? classeId,
    int? eleveId,
    String? du,
    String? au,
    bool? justifie,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['c.annee_scolaire = ?'];
    final args = <Object>[annee];
    if (type != null) {
      where.add('p.type = ?');
      args.add(type);
    }
    if (classeId != null) {
      where.add('e.classe_id = ?');
      args.add(classeId);
    }
    if (eleveId != null) {
      where.add('p.eleve_id = ?');
      args.add(eleveId);
    }
    if (du != null) {
      where.add('p.date >= ?');
      args.add(du);
    }
    if (au != null) {
      where.add('p.date <= ?');
      args.add(au);
    }
    if (justifie != null) {
      where.add('p.justifie = ?');
      args.add(justifie ? 1 : 0);
    }
    final rows = await db.rawQuery(
      '$_select WHERE ${where.join(' AND ')} '
      'ORDER BY p.date DESC, e.nom COLLATE NOCASE, '
      'e.prenoms COLLATE NOCASE, p.id DESC',
      args,
    );
    return rows.map(Presence.fromMap).toList();
  }

  /// Un élève ne peut avoir qu'une absence (et un retard) par jour : on
  /// modifie l'enregistrement existant plutôt que d'en créer un second.
  Future<bool> existe({
    required int eleveId,
    required String date,
    required String type,
    int? exceptId,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'presences',
      columns: ['id'],
      where: 'eleve_id = ? AND date = ? AND type = ?'
          '${exceptId != null ? ' AND id <> ?' : ''}',
      whereArgs: [eleveId, date, type, if (exceptId != null) exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> ajouter(Presence p) async {
    final db = await AppDatabase.instance.database;
    return db.insert('presences', p.toMap());
  }

  Future<void> modifier(Presence p) async {
    final db = await AppDatabase.instance.database;
    await db.update('presences', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> supprimer(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('presences', where: 'id = ?', whereArgs: [id]);
  }

  /// Totaux par élève sur [du]..[au]. Les élèves sans absence ni retard
  /// apparaissent aussi (totaux à 0).
  Future<List<StatsEleve>> statsParEleve({
    required String annee,
    required String du,
    required String au,
    int? classeId,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT e.id, e.nom, e.prenoms, e.sexe, c.nom AS classe_nom,
        COALESCE(SUM(CASE WHEN p.type = 'absence' THEN 1 ELSE 0 END), 0) AS nb_absences,
        COALESCE(SUM(CASE WHEN p.type = 'absence' THEN p.heures ELSE 0 END), 0) AS heures_absence,
        COALESCE(SUM(CASE WHEN p.type = 'absence' AND p.justifie = 1 THEN 1 ELSE 0 END), 0) AS abs_justifiees,
        COALESCE(SUM(CASE WHEN p.type = 'retard' THEN 1 ELSE 0 END), 0) AS nb_retards,
        COALESCE(SUM(CASE WHEN p.type = 'retard' AND p.justifie = 1 THEN 1 ELSE 0 END), 0) AS retards_justifies
      FROM eleves e
      JOIN classes c ON c.id = e.classe_id
      LEFT JOIN presences p
        ON p.eleve_id = e.id AND p.date >= ? AND p.date <= ?
      WHERE c.annee_scolaire = ?${classeId != null ? ' AND e.classe_id = ?' : ''}
      GROUP BY e.id
      ORDER BY e.nom COLLATE NOCASE, e.prenoms COLLATE NOCASE
    ''', [du, au, annee, if (classeId != null) classeId]);
    return rows.map(StatsEleve.fromMap).toList();
  }

  /// Motifs les plus fréquents (absences et retards confondus).
  Future<List<StatMotif>> statsParMotif({
    required String annee,
    required String du,
    required String au,
    int? classeId,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(NULLIF(MIN(TRIM(p.motif)), ''), 'Non précisé') AS motif,
             COUNT(*) AS n
      FROM presences p
      JOIN eleves e ON e.id = p.eleve_id
      JOIN classes c ON c.id = e.classe_id
      WHERE c.annee_scolaire = ? AND p.date >= ? AND p.date <= ?${classeId != null ? ' AND e.classe_id = ?' : ''}
      GROUP BY LOWER(TRIM(COALESCE(p.motif, '')))
      ORDER BY n DESC, motif
      LIMIT 6
    ''', [annee, du, au, if (classeId != null) classeId]);
    return rows
        .map((r) => StatMotif(r['motif'] as String, (r['n'] as num).toInt()))
        .toList();
  }
}
