import '../core/database/app_database.dart';
import '../models/eleve.dart';

class EleveRepository {
  static const _select = '''
    SELECT e.*, c.nom AS classe_nom
    FROM eleves e
    JOIN classes c ON c.id = e.classe_id
  ''';

  /// Élèves de l'année scolaire, triés par ordre alphabétique.
  /// [classeId] : filtre par classe. [recherche] : nom, prénom ou matricule.
  Future<List<Eleve>> rechercher({
    required String annee,
    int? classeId,
    String? recherche,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['c.annee_scolaire = ?'];
    final args = <Object>[annee];
    if (classeId != null) {
      where.add('e.classe_id = ?');
      args.add(classeId);
    }
    final q = recherche?.trim() ?? '';
    if (q.isNotEmpty) {
      where.add("(e.nom LIKE ? OR e.prenoms LIKE ? "
          "OR (e.nom || ' ' || e.prenoms) LIKE ? "
          "OR (e.prenoms || ' ' || e.nom) LIKE ? "
          "OR e.matricule LIKE ?)");
      final like = '%$q%';
      args.addAll([like, like, like, like, like]);
    }
    final rows = await db.rawQuery(
      '$_select WHERE ${where.join(' AND ')} '
      'ORDER BY e.nom COLLATE NOCASE, e.prenoms COLLATE NOCASE',
      args,
    );
    return rows.map(Eleve.fromMap).toList();
  }

  Future<Eleve?> trouver(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('$_select WHERE e.id = ? LIMIT 1', [id]);
    return rows.isEmpty ? null : Eleve.fromMap(rows.first);
  }

  Future<bool> matriculeExiste(String matricule, {int? exceptId}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'eleves',
      columns: ['id'],
      where: 'LOWER(matricule) = LOWER(?)'
          '${exceptId != null ? ' AND id <> ?' : ''}',
      whereArgs: [matricule, if (exceptId != null) exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> ajouter(Eleve e) async {
    final db = await AppDatabase.instance.database;
    return db.insert('eleves', e.toMap());
  }

  Future<void> modifier(Eleve e) async {
    final db = await AppDatabase.instance.database;
    await db.update('eleves', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> supprimer(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('eleves', where: 'id = ?', whereArgs: [id]);
  }
}
