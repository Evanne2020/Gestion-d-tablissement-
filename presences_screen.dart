import 'package:flutter/material.dart';

import '../core/periode.dart';
import '../core/ui.dart';
import '../core/utils.dart';
import '../models/classe.dart';
import '../models/presence.dart';
import '../repositories/classe_repository.dart';
import '../repositories/parametre_repository.dart';
import '../repositories/presence_repository.dart';
import '../widgets/filtre_classe.dart';
import '../widgets/presence_tile.dart';
import '../widgets/selecteur_periode.dart';
import 'presence_form_screen.dart';

/// Liste des absences OU des retards, avec filtres, ajout, modification,
/// suppression. [type] : Presence.absence ou Presence.retard.
class PresencesScreen extends StatefulWidget {
  final String type;
  const PresencesScreen({super.key, required this.type});

  @override
  State<PresencesScreen> createState() => _PresencesScreenState();
}

class _PresencesScreenState extends State<PresencesScreen> {
  final _repo = PresenceRepository();
  final _classesRepo = ClasseRepository();
  final _params = ParametreRepository();

  String _annee = '';
  List<Classe> _classes = [];
  List<Presence> _liste = [];
  int? _classeId;
  Periode? _periode;
  bool? _justifie;
  bool _chargement = true;

  bool get _absence => widget.type == Presence.absence;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _annee = await _params.anneeScolaire();
      _classes = await _classesRepo.lister(_annee);
      _periode = Periode.calculer(TypePeriode.mois, annee: _annee);
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
      type: widget.type,
      classeId: _classeId,
      du: _periode!.du,
      au: _periode!.au,
      justifie: _justifie,
    );
    if (!mounted) return;
    setState(() {
      _liste = liste;
      _chargement = false;
    });
  }

  Future<void> _ajouter() async {
    if (_classes.isEmpty) {
      afficherMessage(context, 'Créez d\'abord une classe et des élèves.',
          erreur: true);
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PresenceFormScreen(
            type: widget.type, classeIdParDefaut: _classeId),
      ),
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
      titre: _absence ? 'Supprimer cette absence ?' : 'Supprimer ce retard ?',
      message: '${p.eleveNomComplet} · ${formatDateFr(p.date)}. '
          'Cette action est irréversible.',
    );
    if (!ok) return;
    try {
      await _repo.supprimer(p.id!);
      if (!mounted) return;
      afficherMessage(context, _absence ? 'Absence supprimée.' : 'Retard supprimé.');
      _recharger();
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'La suppression a échoué.', erreur: true);
    }
  }

  String get _resume {
    final n = _liste.length;
    final just = _liste.where((p) => p.justifie).length;
    if (_absence) {
      final h = _liste.fold<double>(0, (s, p) => s + p.heures);
      return '$n absence(s) · ${formatHeures(h)} · $just justifiée(s)';
    }
    return '$n retard(s) · $just justifié(s)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_absence ? 'Absences' : 'Retards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.add),
        label: Text(_absence ? 'Nouvelle absence' : 'Nouveau retard'),
      ),
      body: _chargement || _periode == null
          ? const Center(child: CircularProgressIndicator())
          : centrer(
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        FiltreClasse(
                          classes: _classes,
                          valeur: _classeId,
                          onChanged: (v) {
                            setState(() => _classeId = v);
                            _recharger();
                          },
                        ),
                        const SizedBox(height: 10),
                        SelecteurPeriode(
                          periode: _periode!,
                          annee: _annee,
                          onChanged: (p) {
                            setState(() => _periode = p);
                            _recharger();
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final (libelle, valeur) in const <(String, bool?)>[
                              ('Tous', null),
                              ('Justifiés', true),
                              ('Non justifiés', false),
                            ])
                              ChoiceChip(
                                label: Text(libelle),
                                selected: _justifie == valeur,
                                onSelected: (_) {
                                  setState(() => _justifie = valeur);
                                  _recharger();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_resume,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                  ),
                  Expanded(
                    child: _liste.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                _absence
                                    ? 'Aucune absence sur cette période.'
                                    : 'Aucun retard sur cette période.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 96),
                            itemCount: _liste.length,
                            itemBuilder: (_, i) => PresenceTile(
                              presence: _liste[i],
                              afficherEleve: true,
                              onModifier: () => _modifier(_liste[i]),
                              onSupprimer: () => _supprimer(_liste[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
