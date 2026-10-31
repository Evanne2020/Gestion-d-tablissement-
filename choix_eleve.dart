import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/eleve.dart';

/// Fenêtre de choix d'un élève avec recherche (nom, prénom, matricule).
Future<Eleve?> choisirEleve(BuildContext context, List<Eleve> eleves) {
  return showModalBottomSheet<Eleve>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ChoixEleve(eleves: eleves),
  );
}

class _ChoixEleve extends StatefulWidget {
  final List<Eleve> eleves;
  const _ChoixEleve({required this.eleves});

  @override
  State<_ChoixEleve> createState() => _ChoixEleveState();
}

class _ChoixEleveState extends State<_ChoixEleve> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final liste = q.isEmpty
        ? widget.eleves
        : widget.eleves
            .where((e) =>
                e.nomComplet.toLowerCase().contains(q) ||
                '${e.prenoms} ${e.nom}'.toLowerCase().contains(q) ||
                (e.matricule ?? '').toLowerCase().contains(q))
            .toList();
    final bas = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bas),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un élève',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: liste.isEmpty
                  ? const Center(child: Text('Aucun élève trouvé.'))
                  : ListView.builder(
                      itemCount: liste.length,
                      itemBuilder: (_, i) {
                        final e = liste[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                couleurSexe(e.sexe).withValues(alpha: 0.15),
                            foregroundColor: couleurSexe(e.sexe),
                            child: Text(e.sexe),
                          ),
                          title: Text(e.nomComplet),
                          subtitle: e.matricule == null
                              ? null
                              : Text(e.matricule!),
                          onTap: () => Navigator.pop(context, e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
