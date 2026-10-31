import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/classe.dart';
import '../models/eleve.dart';
import '../repositories/classe_repository.dart';
import '../repositories/eleve_repository.dart';
import '../repositories/parametre_repository.dart';
import 'eleve_fiche_screen.dart';
import 'eleve_form_screen.dart';

class ElevesScreen extends StatefulWidget {
  /// Classe présélectionnée dans le filtre (optionnel).
  final int? classeIdInitial;
  const ElevesScreen({super.key, this.classeIdInitial});

  @override
  State<ElevesScreen> createState() => _ElevesScreenState();
}

class _ElevesScreenState extends State<ElevesScreen> {
  final _eleves = EleveRepository();
  final _classesRepo = ClasseRepository();
  final _params = ParametreRepository();
  final _rechercheCtrl = TextEditingController();

  Timer? _debounce;
  String _annee = '';
  List<Classe> _classes = [];
  List<Eleve> _liste = [];
  int? _classeId;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _classeId = widget.classeIdInitial;
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _annee = await _params.anneeScolaire();
      _classes = await _classesRepo.lister(_annee);
      if (_classeId != null && !_classes.any((c) => c.id == _classeId)) {
        _classeId = null;
      }
      await _recharger();
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Impossible de charger les élèves.',
          erreur: true);
    }
  }

  Future<void> _recharger() async {
    final liste = await _eleves.rechercher(
      annee: _annee,
      classeId: _classeId,
      recherche: _rechercheCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _liste = liste;
      _chargement = false;
    });
  }

  void _surRecherche(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _recharger);
  }

  Future<void> _ajouter() async {
    if (_classes.isEmpty) {
      afficherMessage(context, 'Créez d\'abord une classe (menu Classes).',
          erreur: true);
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EleveFormScreen(classeIdParDefaut: _classeId),
      ),
    );
    if (ok == true) _recharger();
  }

  Future<void> _ouvrirFiche(Eleve e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EleveFicheScreen(eleveId: e.id!)),
    );
    _recharger();
  }

  String _initiales(Eleve e) {
    final a = e.nom.isNotEmpty ? e.nom[0] : '?';
    final b = e.prenoms.isNotEmpty ? e.prenoms[0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final recherche = _rechercheCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Élèves')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nouvel élève'),
      ),
      body: centrer(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _rechercheCtrl,
                    onChanged: (v) {
                      setState(() {}); // met à jour le bouton d'effacement
                      _surRecherche(v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, prénom ou matricule',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _rechercheCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _rechercheCtrl.clear();
                                setState(() {});
                                _recharger();
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Classe',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        isExpanded: true,
                        value: _classeId,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Toutes les classes'),
                          ),
                          for (final c in _classes)
                            DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.nom),
                            ),
                        ],
                        onChanged: (v) {
                          setState(() => _classeId = v);
                          _recharger();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_liste.length} élève(s)',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            Expanded(
              child: _chargement
                  ? const Center(child: CircularProgressIndicator())
                  : _liste.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              recherche.isNotEmpty
                                  ? 'Aucun élève ne correspond à « $recherche ».'
                                  : 'Aucun élève ici pour le moment.\n'
                                      'Appuyez sur « Nouvel élève » pour en ajouter.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: _liste.length,
                          itemBuilder: (_, i) => _tuile(_liste[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuile(Eleve e) {
    final couleur = couleurSexe(e.sexe);
    final details = [
      if (e.matricule != null) e.matricule!,
      if (e.classeNom != null) e.classeNom!,
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _ouvrirFiche(e),
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.15),
          foregroundColor: couleur,
          child: Text(_initiales(e),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(e.nomComplet,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(details.isEmpty ? 'Sans matricule' : details),
        trailing: Text(
          e.sexe,
          style: TextStyle(
              color: couleur, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
