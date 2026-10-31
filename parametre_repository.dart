import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../core/utils.dart';

class ParametreRepository {
  static const _cleAnnee = 'annee_scolaire';
  static const _cleNomEtablissement = 'nom_etablissement';

  Future<String> anneeScolaire() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('parametres',
        where: 'cle = ?', whereArgs: [_cleAnnee], limit: 1);
    if (rows.isNotEmpty) return rows.first['valeur'] as String;
    final defaut = anneeScolaireParDefaut();
    await definirAnneeScolaire(defaut);
    return defaut;
  }

  Future<void> definirAnneeScolaire(String valeur) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'parametres',
      {'cle': _cleAnnee, 'valeur': valeur},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Nom de l'établissement (en-tête des rapports), ou null s'il n'a pas
  /// encore été saisi. Stocké dans la table `parametres` (clé/valeur) :
  /// aucune modification de la structure de la base.
  Future<String?> nomEtablissement() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('parametres',
        where: 'cle = ?', whereArgs: [_cleNomEtablissement], limit: 1);
    if (rows.isEmpty) return null;
    final v = (rows.first['valeur'] as String?)?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  /// Enregistre le nom ; un nom vide efface le paramètre.
  Future<void> definirNomEtablissement(String nom) async {
    final db = await AppDatabase.instance.database;
    final v = nom.trim();
    if (v.isEmpty) {
      await db.delete('parametres',
          where: 'cle = ?', whereArgs: [_cleNomEtablissement]);
      return;
    }
    await db.insert(
      'parametres',
      {'cle': _cleNomEtablissement, 'valeur': v},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
