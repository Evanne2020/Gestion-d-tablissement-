import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Accès unique à la base SQLite locale (aucun réseau).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbFolder = 'GEST-ETAB';
  static const _dbName = 'gest_etab.db';
  static const _version = 1;

  Database? _db;

  /// À appeler une fois au démarrage (avant d'ouvrir la base).
  static void initPlatform() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async => _db ??= await _open();

  Future<String> get dbPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFolder, _dbName);
  }

  Future<Database> _open() async {
    final path = await dbPath;
    await Directory(p.dirname(path)).create(recursive: true);
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  /// Fermer la base (nécessaire avant une restauration de sauvegarde).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      )''');

    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        annee_scolaire TEXT NOT NULL,
        UNIQUE (nom, annee_scolaire)
      )''');

    await db.execute('''
      CREATE TABLE eleves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matricule TEXT,
        nom TEXT NOT NULL,
        prenoms TEXT NOT NULL,
        sexe TEXT NOT NULL CHECK (sexe IN ('F','M')),
        date_naissance TEXT,
        lieu_naissance TEXT,
        telephone TEXT,
        nom_parent TEXT,
        telephone_parent TEXT,
        classe_id INTEGER NOT NULL,
        FOREIGN KEY (classe_id) REFERENCES classes (id) ON DELETE CASCADE
      )''');
    await db.execute('CREATE INDEX idx_eleves_classe ON eleves (classe_id)');

    // type : 'absence' ou 'retard'
    await db.execute('''
      CREATE TABLE presences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eleve_id INTEGER NOT NULL,
        date TEXT NOT NULL,            -- format AAAA-MM-JJ
        type TEXT NOT NULL CHECK (type IN ('absence','retard')),
        heures REAL NOT NULL DEFAULT 0,
        heure_arrivee TEXT,            -- pour les retards
        motif TEXT,
        justifie INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (eleve_id) REFERENCES eleves (id) ON DELETE CASCADE
      )''');
    await db.execute('CREATE INDEX idx_presences_date ON presences (date)');
    await db.execute(
        'CREATE INDEX idx_presences_eleve ON presences (eleve_id)');
  }
}
