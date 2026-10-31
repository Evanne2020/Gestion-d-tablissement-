import 'package:flutter/material.dart';

import '../core/periode.dart';
import '../core/ui.dart';
import '../core/utils.dart';
import '../models/eleve.dart';
import '../models/presence.dart';
import '../repositories/eleve_repository.dart';
import '../repositories/parametre_repository.dart';
import '../repositories/presence_repository.dart';
import '../widgets/presence_tile.dart';
import '../widgets/selecteur_periode.dart';
import 'presence_form_screen.dart';

/// Historique des absences et retards d'un élève, avec totaux.
class EleveHistoriqueScreen extends StatefulWidget {
  final int eleveId;
  const EleveHistoriqueScreen({super.key, required this.eleveId});

  @override
  State<EleveHistoriqueScreen> createState() => _EleveHistoriqueScreenState();
}

class _EleveHistoriqueScreenState extends State<EleveHistoriqueScreen> {
  final _repo = PresenceRepository();

  String _annee = '';
  Eleve? _eleve;
  List<Presence> _liste = [];
  Periode? _periode;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _annee = await ParametreRepository().anneeScolaire();
      _eleve = await EleveRepository().trouver(widget.eleveId);
      _periode = Periode.calculer(TypePeriode.annee, annee: _annee);
      await _recharger();
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Chargement impossible.', erreur: true);
    }
  }

  Future<void> _recharger() async {
    final liste = await _repo.lister(
      annee: _annee,
      eleveId: widget.eleveId,
      du: _periode!.du,
      au: _periode!.au,
    );
    if (!mounted) return;
    setState(() {
      _liste = liste;
      _chargement = false;
    });
  }

  Future<void> _ajouter(String type) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PresenceFormScreen(type: type, eleve: _eleve)),
    );
    if (ok == true) _recharger();
  }

  Future<void> _modifier(Presence p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PresenceFormScreen(type: p.type, presence: p)),
    );
    if (ok == true) _recharger();
  }

  Future<void> _supprimer(Presence p) async {
    final ok = await confirmer(
      context,
      titre: p.estAbsence ? 'Supprimer cette absence ?' : 'Supprimer ce retard ?',
      message: 'Enregistrement du ${formatDateFr(p.date)}. '
          'Cette action est irréversible.',
    );
    if (!ok) return;
    try {
      await _repo.supprimer(p.id!);
      if (!mounted) return;
      afficherMessage(context, 'Enregistrement supprimé.');
      _recharger();
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'La suppression a échoué.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _eleve;
    return Scaffold(
      appBar: AppBar(title: const Text('Absences et retards')),
      body: _chargement || _periode == null
          ? const Center(child: CircularProgressIndicator())
          : e == null
              ? const Center(child: Text('Élève introuvable.'))
              : centrer(_contenu(e)),
    );
  }

  Widget _contenu(Eleve e) {
    final absences = _liste.where((p) => p.estAbsence).toList();
    final retards = _liste.where((p) => !p.estAbsence).toList();
    final heures = absences.fold<double>(0, (s, p) => s + p.heures);
    final nonJustAbs = absences.where((p) => !p.justifie).length;
    final nonJustRet = retards.where((p) => !p.justifie).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(e.nomComplet,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text('${e.classeNom ?? ''}${e.matricule != null ? ' · ${e.matricule}' : ''}'),
        const SizedBox(height: 12),
        SelecteurPeriode(
          periode: _periode!,
          annee: _annee,
          onChanged: (p) {
            setState(() => _periode = p);
            _recharger();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _carte('Absences', '${absences.length}', Colors.red.shade700),
            _carte('Heures d\'absence', formatHeures(heures), Colors.red.shade700),
            _carte('Abs. non justifiées', '$nonJustAbs', Colors.orange.shade800),
            _carte('Retards', '${retards.length}', Colors.blue.shade700),
            _carte('Retards non justifiés', '$nonJustRet', Colors.orange.shade800),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _ajouter(Presence.absence),
                icon: const Icon(Icons.event_busy),
                label: const Text('Nouvelle absence'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _ajouter(Presence.retard),
                icon: const Icon(Icons.schedule),
                label: const Text('Nouveau retard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_liste.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucune absence ni retard sur cette période.',
                textAlign: TextAlign.center),
          )
        else
          for (final p in _liste)
            PresenceTile(
              presence: p,
              afficherEleve: false,
              onModifier: () => _modifier(p),
              onSupprimer: () => _supprimer(p),
            ),
      ],
    );
  }

  Widget _carte(String libelle, String valeur, Color couleur) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valeur,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: couleur)),
              const SizedBox(height: 2),
              Text(libelle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
