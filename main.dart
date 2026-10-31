import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initPlatform(); // SQLite via FFI sur Windows
  await AppDatabase.instance.database; // ouvre / crée la base
  runApp(const GestEtabApp());
}
