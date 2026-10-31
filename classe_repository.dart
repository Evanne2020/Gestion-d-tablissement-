import '../core/database/app_database.dart';
import '../models/classe.dart';

class ClasseRepository {
  Future<List<Classe>> lister(String anneeScolaire) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('classes',
        where: 'annee_scolaire = ?',
        whereArgs: [anneeScolaire],
        orderBy: 'nom COLLATE NOCASE');
    return rows.map(Classe.fromMap).toList();
  }

  /// Classes de l'année avec effectif total, filles et garçons.
  Future<List<ClasseAvecEffectif>> listerAvecEffectif(
      String anneeScolaire) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.nom, c.annee_scolaire,
             COUNT(e.id) AS effectif,
             COALESCE(SUM(CASE WHEN e.sexe = 'F' THEN 1 ELSE 0 END), 0) AS filles,
             COALESCE(SUM(CASE WHEN e.sexe = 'M' THEN 1 ELSE 0 END), 0) AS garcons
      FROM classes c
      LEFT JOIN eleves e ON e.classe_id = c.id
      WHERE c.annee_scolaire = ?
      GROUP BY c.id
      ORDER BY c.nom COLLATE NOCASE
    ''', [anneeScolaire]);
    return rows.map(ClasseAvecEffectif.fromMap).toList();
  }

  Future<bool> existe(String nom, String anneeScolaire, {int? exceptId}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'classes',
      columns: ['id'],
      where: 'LOWER(nom) = LOWER(?) AND annee_scolaire = ?'
          '${exceptId != null ? ' AND id <> ?' : ''}',
      whereArgs: [nom, anneeScolaire, if (exceptId != null) exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> ajouter(Classe c) async {
    final db = await AppDatabase.instance.database;
    return db.insert('classes', c.toMap());
  }

  Future<void> modifier(Classe c) async {
    final db = await AppDatabase.instance.database;
    await db.update('classes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  /// Nombre d'élèves inscrits dans la classe.
  Future<int> compterEleves(int id) async {
    final db = await AppDatabase.instance.database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM eleves WHERE classe_id = ?', [id]);
    return (r.first['n'] as num).toInt();
  }

  /// Supprime une classe VIDE. Si elle contient encore des élèves, la
  /// suppression est refusée ([ClasseNonVideException]) : aucun élève n'est
  /// jamais supprimé par ce biais.
  Future<void> supprimer(int id) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final r = await txn.rawQuery(
          'SELECT COUNT(*) AS n FROM eleves WHERE classe_id = ?', [id]);
      final n = (r.first['n'] as num).toInt();
      if (n > 0) throw ClasseNonVideException(n);
      await txn.delete('classes', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Transfère tous les élèves vers [versId], puis supprime la classe [id].
  /// Opération atomique : tout réussit, ou rien n'est modifié.
  /// Retourne le nombre d'élèves transférés.
  Future<int> transfererEtSupprimer(int id, int versId) async {
    if (id == versId) {
      throw ArgumentError('La classe de destination doit être différente.');
    }
    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final n = await txn.update('eleves', {'classe_id': versId},
          where: 'classe_id = ?', whereArgs: [id]);
      await txn.delete('classes', where: 'id = ?', whereArgs: [id]);
      return n;
    });
  }
}

class ClasseNonVideException implements Exception {
  final int effectif;
  const ClasseNonVideException(this.effectif);

  @override
  String toString() => 'La classe contient encore $effectif élève(s).';
}
