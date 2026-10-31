import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/presence.dart';

/// Ligne d'une absence ou d'un retard.
/// [afficherEleve] : true dans les listes globales, false dans l'historique
/// d'un élève (où le nom est déjà en en-tête).
class PresenceTile extends StatelessWidget {
  final Presence presence;
  final bool afficherEleve;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const PresenceTile({
    super.key,
    required this.presence,
    required this.afficherEleve,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final p = presence;
    final detail = p.estAbsence
        ? 'Absence de ${formatHeures(p.heures)}'
        : (p.heureArrivee != null
            ? 'Retard · arrivé(e) à ${p.heureArrivee}'
            : 'Retard');
    final statut = p.estAbsence
        ? (p.justifie ? 'Absence justifiée' : 'Absence non justifiée')
        : (p.justifie ? 'Retard justifié' : 'Retard non justifié');
    final couleur = p.justifie ? Colors.green.shade700 : Colors.orange.shade800;
    final motif = (p.motif ?? '').trim();

    final titre = afficherEleve
        ? p.eleveNomComplet
        : '${formatDateFr(p.date)} · ${p.estAbsence ? 'Absence' : 'Retard'}';
    final ligne1 = afficherEleve
        ? [if (p.classeNom != null) p.classeNom!, formatDateFr(p.date), detail]
            .join(' · ')
        : detail;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        isThreeLine: true,
        onTap: onModifier,
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.15),
          foregroundColor: couleur,
          child: Icon(p.estAbsence ? Icons.event_busy : Icons.schedule),
        ),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ligne1),
            if (motif.isNotEmpty) Text('Motif : $motif'),
            Text(statut,
                style: TextStyle(color: couleur, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (v) => v == 'modifier' ? onModifier() : onSupprimer(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'modifier',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'supprimer',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Supprimer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
