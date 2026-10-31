import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/classe.dart';
import '../reports/liste_eleves_pdf.dart';
import '../reports/rapport_base.dart';
import '../repositories/classe_repository.dart';
import '../repositories/eleve_repository.dart';
import '../repositories/parametre_repository.dart';
import '../widgets/filtre_classe.dart';
import 'apercu_pdf_screen.dart';

/// Menu des rapports PDF (étape 4a : liste des élèves).
class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  final _params = ParametreRepository();
  final _classesRepo = ClasseRepository();
  final _elevesRepo = EleveRepository();

  String _annee = '';
  String? _nomEtab;
  List<Classe> _classes = [];
  int? _classeId;
  bool _chargement = true;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _annee = await _params.anneeScolaire();
      _nomEtab = await _params.nomEtablissement();
      _classes = await _classesRepo.lister(_annee);
    } catch (_) {
      if (mounted) {
        afficherMessage(context, 'Chargement impossible.', erreur: true);
      }
    }
    if (!mounted) return;
    setState(() => _chargement = false);
  }

  Future<void> _modifierNom() async {
    final nom = await showDialog<String>(
      context: context,
      builder: (_) => _NomEtablissementDialog(nomInitial: _nomEtab),
    );
    if (nom == null) return;
    try {
      await _params.definirNomEtablissement(nom);
      if (!mounted) return;
      setState(() => _nomEtab = nom.trim().isEmpty ? null : nom.trim());
      afficherMessage(context, 'Nom de l\'établissement enregistré.');
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'L\'enregistrement a échoué.', erreur: true);
    }
  }

  /// Le nom est nécessaire pour l'en-tête : on le demande s'il manque.
  Future<bool> _assurerNom() async {
    if (_nomEtab != null) return true;
    await _modifierNom();
    return _nomEtab != null;
  }

  Future<void> _genererListeEleves() async {
    if (_enCours) return;
    if (!await _assurerNom()) return;
    if (!mounted) return;
    setState(() => _enCours = true);
    try {
      final eleves =
          await _elevesRepo.rechercher(annee: _annee, classeId: _classeId);
      if (eleves.isEmpty) {
        if (!mounted) return;
        afficherMessage(context, 'Aucun élève à imprimer pour cette sélection.',
            erreur: true);
        return;
      }
      final classeNom =
          _classes.where((c) => c.id == _classeId).map((c) => c.nom).firstOrNull;
      final base = await RapportBase.charger(
          nomEtablissement: _nomEtab!, anneeScolaire: _annee);
      final octets = await ListeElevesPdf.generer(
          base: base, eleves: eleves, classeNom: classeNom);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ApercuPdfScreen(
            titre: ListeElevesPdf.titre,
            nomFichier:
                RapportBase.nomFichier('liste_eleves', classeNom: classeNom),
            octets: octets,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'La génération du PDF a échoué.', erreur: true);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports PDF')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : centrer(
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: const Text('Nom de l\'établissement'),
                      subtitle: Text(_nomEtab ??
                          'Non renseigné — appuyez pour le saisir'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _modifierNom,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: Text('Année scolaire $_annee',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.groups_outlined),
                            const SizedBox(width: 8),
                            Text('Liste des élèves',
                                style: Theme.of(context).textTheme.titleMedium),
                          ]),
                          const SizedBox(height: 4),
                          const Text(
                              'Une classe ou toutes les classes (une page par classe).'),
                          const SizedBox(height: 12),
                          FiltreClasse(
                            classes: _classes,
                            valeur: _classeId,
                            onChanged: (v) => setState(() => _classeId = v),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _enCours ? null : _genererListeEleves,
                            icon: _enCours
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Générer le PDF'),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Card(
                    child: ListTile(
                      enabled: false,
                      leading: Icon(Icons.event_busy_outlined),
                      title: Text('Rapport d\'absences par classe'),
                      subtitle: Text('Bientôt (étape 4b)'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      enabled: false,
                      leading: Icon(Icons.schedule_outlined),
                      title: Text('Rapport de retards'),
                      subtitle: Text('Bientôt (étape 4b)'),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      enabled: false,
                      leading: Icon(Icons.bar_chart_outlined),
                      title: Text('Rapport de statistiques'),
                      subtitle: Text('Bientôt (étape 4c)'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Saisie du nom de l'établissement (en-tête des rapports).
class _NomEtablissementDialog extends StatefulWidget {
  final String? nomInitial;
  const _NomEtablissementDialog({this.nomInitial});

  @override
  State<_NomEtablissementDialog> createState() =>
      _NomEtablissementDialogState();
}

class _NomEtablissementDialogState extends State<_NomEtablissementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.nomInitial ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nom de l\'établissement'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _valider(),
          decoration: const InputDecoration(
            labelText: 'Nom affiché en tête des rapports',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Saisissez le nom de l\'établissement.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Enregistrer')),
      ],
    );
  }
}
