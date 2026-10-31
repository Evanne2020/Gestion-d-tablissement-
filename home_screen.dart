import 'package:flutter/material.dart';

import 'classes_screen.dart';
import '../models/presence.dart';
import 'eleves_screen.dart';
import 'presences_screen.dart';
import 'rapports_screen.dart';
import 'statistiques_screen.dart';

class _Module {
  final String titre;
  final IconData icone;
  final int etape;
  final Widget Function()? page; // null = pas encore développé
  const _Module(this.titre, this.icone, this.etape, [this.page]);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<_Module> get _modules => [
        _Module('Classes', Icons.class_outlined, 2, () => const ClassesScreen()),
        _Module('Élèves', Icons.groups_outlined, 2, () => const ElevesScreen()),
        _Module('Absences', Icons.event_busy_outlined, 3,
            () => const PresencesScreen(type: Presence.absence)),
        _Module('Retards', Icons.schedule_outlined, 3,
            () => const PresencesScreen(type: Presence.retard)),
        _Module('Statistiques', Icons.bar_chart_outlined, 3,
            () => const StatistiquesScreen()),
        _Module('Rapports PDF', Icons.picture_as_pdf_outlined, 4,
            () => const RapportsScreen()),
        const _Module('Export Excel', Icons.table_chart_outlined, 5),
        const _Module('Sauvegarde', Icons.backup_outlined, 6),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GEST-ÉTAB')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final m in _modules)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (m.page != null) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => m.page!()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '${m.titre} : prévu à l\'étape ${m.etape}'),
                    ));
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(m.icone, size: 44),
                    const SizedBox(height: 8),
                    Text(m.titre,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
