import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../core/utils.dart';
import '../models/eleve.dart';
import '../repositories/eleve_repository.dart';
import 'eleve_form_screen.dart';
import 'eleve_historique_screen.dart';

/// Fiche individuelle d'un élève (consultation, modification, suppression).
class EleveFicheScreen extends StatefulWidget {
  final int eleveId;
  const EleveFicheScreen({super.key, required this.eleveId});

  @override
  State<EleveFicheScreen> createState() => _EleveFicheScreenState();
}

class _EleveFicheScreenState extends State<EleveFicheScreen> {
  final _repo = EleveRepository();
  Eleve? _eleve;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final e = await _repo.trouver(widget.eleveId);
      if (!mounted) return;
      setState(() {
        _eleve = e;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Impossible de charger la fiche.',
          erreur: true);
    }
  }

  Future<void> _modifier() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EleveFormScreen(eleve: _eleve)),
    );
    if (ok == true) _charger();
  }

  Future<void> _supprimer() async {
    final e = _eleve!;
    final ok = await confirmer(
      context,
      titre: 'Supprimer cet élève ?',
      message: '${e.nomComplet} sera supprimé(e) définitivement, avec ses '
          'absences et retards. Cette action est irréversible.',
    );
    if (!ok) return;
    try {
      await _repo.supprimer(e.id!);
      if (!mounted) return;
      afficherMessage(context, '${e.nomComplet} a été supprimé(e).');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'La suppression a échoué.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _eleve;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche de l\'élève'),
        actions: [
          if (e != null) ...[
            IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: _modifier),
            IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: _supprimer),
          ],
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : e == null
              ? const Center(child: Text('Élève introuvable.'))
              : centrer(_contenu(e)),
    );
  }

  Widget _contenu(Eleve e) {
    final couleur = couleurSexe(e.sexe);
    final age = calculerAge(e.dateNaissance);
    final dateTxt = e.dateNaissance == null
        ? '—'
        : '${formatDateFr(e.dateNaissance)}${age != null ? '  ($age ans)' : ''}';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: couleur.withValues(alpha: 0.15),
            foregroundColor: couleur,
            child: Text(
              ((e.nom.isNotEmpty ? e.nom[0] : '?') +
                      (e.prenoms.isNotEmpty ? e.prenoms[0] : ''))
                  .toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(e.nomComplet,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(e.classeNom ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _ligne(Icons.badge_outlined, 'Matricule', e.matricule ?? '—'),
              _ligne(Icons.wc, 'Sexe',
                  e.sexe == 'F' ? 'Féminin' : 'Masculin',
                  couleurValeur: couleur),
              _ligne(Icons.cake_outlined, 'Date de naissance', dateTxt),
              _ligne(Icons.class_outlined, 'Classe', e.classeNom ?? '—'),
              _ligne(Icons.family_restroom_outlined, 'Nom du parent',
                  e.nomParent ?? '—'),
              _ligne(Icons.phone_outlined, 'Téléphone du parent',
                  e.telephoneParent ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EleveHistoriqueScreen(eleveId: e.id!)),
          ),
          icon: const Icon(Icons.history),
          label: const Text('Absences et retards'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _ligne(IconData icone, String libelle, String valeur,
      {Color? couleurValeur}) {
    return ListTile(
      leading: Icon(icone),
      title: Text(libelle, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(
        valeur,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: couleurValeur),
      ),
    );
  }
}
