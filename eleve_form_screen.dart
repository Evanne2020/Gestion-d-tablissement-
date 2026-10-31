import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../core/utils.dart';
import '../models/classe.dart';
import '../models/eleve.dart';
import '../repositories/classe_repository.dart';
import '../repositories/eleve_repository.dart';
import '../repositories/parametre_repository.dart';

/// Formulaire d'ajout / modification d'un élève.
/// Retourne `true` (via Navigator.pop) si l'élève a été enregistré.
class EleveFormScreen extends StatefulWidget {
  final Eleve? eleve;
  final int? classeIdParDefaut;
  const EleveFormScreen({super.key, this.eleve, this.classeIdParDefaut});

  @override
  State<EleveFormScreen> createState() => _EleveFormScreenState();
}

class _EleveFormScreenState extends State<EleveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = EleveRepository();

  late final TextEditingController _matricule;
  late final TextEditingController _nom;
  late final TextEditingController _prenoms;
  late final TextEditingController _nomParent;
  late final TextEditingController _telParent;
  late final TextEditingController _dateText;

  List<Classe> _classes = [];
  int? _classeId;
  String? _sexe;
  String? _dateIso;

  String? _erreurMatricule;
  String? _erreurSexe;
  String? _erreurClasse;
  bool _chargement = true;
  bool _enCours = false;

  bool get _modification => widget.eleve != null;

  @override
  void initState() {
    super.initState();
    final e = widget.eleve;
    _matricule = TextEditingController(text: e?.matricule ?? '');
    _nom = TextEditingController(text: e?.nom ?? '');
    _prenoms = TextEditingController(text: e?.prenoms ?? '');
    _nomParent = TextEditingController(text: e?.nomParent ?? '');
    _telParent = TextEditingController(text: e?.telephoneParent ?? '');
    _sexe = e?.sexe;
    _dateIso = e?.dateNaissance;
    _dateText = TextEditingController(
        text: _dateIso == null ? '' : formatDateFr(_dateIso));
    _classeId = e?.classeId ?? widget.classeIdParDefaut;
    _chargerClasses();
  }

  @override
  void dispose() {
    _matricule.dispose();
    _nom.dispose();
    _prenoms.dispose();
    _nomParent.dispose();
    _telParent.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _chargerClasses() async {
    try {
      final annee = await ParametreRepository().anneeScolaire();
      final classes = await ClasseRepository().lister(annee);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (_classeId != null && !classes.any((c) => c.id == _classeId)) {
          _classeId = null;
        }
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Impossible de charger les classes.',
          erreur: true);
    }
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final initiale = DateTime.tryParse(_dateIso ?? '') ??
        DateTime(maintenant.year - 14, 1, 1);
    final d = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(1980),
      lastDate: maintenant,
      helpText: 'Date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (d == null) return;
    setState(() {
      _dateIso = toIsoDate(d);
      _dateText.text = formatDateFr(_dateIso);
    });
  }

  String? _validerTelephone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null; // facultatif
    final chiffres = t.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[0-9+\s().-]+$').hasMatch(t) ||
        chiffres.length < 8 ||
        chiffres.length > 15) {
      return 'Numéro invalide (8 à 15 chiffres).';
    }
    return null;
  }

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final matricule = _matricule.text.trim().toUpperCase();

    // Contrôle du doublon de matricule avant la validation du formulaire
    _erreurMatricule = null;
    try {
      if (matricule.isNotEmpty &&
          await _repo.matriculeExiste(matricule,
              exceptId: widget.eleve?.id)) {
        _erreurMatricule = 'Ce matricule est déjà utilisé.';
      }
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'Vérification du matricule impossible.',
          erreur: true);
      return;
    }
    if (!mounted) return;

    final valide = _formKey.currentState!.validate();
    setState(() {
      _erreurSexe = _sexe == null ? 'Indiquez le sexe.' : null;
      _erreurClasse = _classeId == null ? 'Choisissez une classe.' : null;
    });
    if (!valide || _sexe == null || _classeId == null) return;

    final ancien = widget.eleve;
    final eleve = Eleve(
      id: ancien?.id,
      matricule: matricule.isEmpty ? null : matricule,
      nom: _nom.text.trim().toUpperCase(),
      prenoms: capitaliserMots(_prenoms.text),
      sexe: _sexe!,
      dateNaissance: _dateIso,
      lieuNaissance: ancien?.lieuNaissance,
      telephone: ancien?.telephone,
      nomParent: nullSiVide(_nomParent.text),
      telephoneParent: nullSiVide(_telParent.text),
      classeId: _classeId!,
    );

    setState(() => _enCours = true);
    try {
      if (_modification) {
        await _repo.modifier(eleve);
      } else {
        await _repo.ajouter(eleve);
      }
      if (!mounted) return;
      afficherMessage(
        context,
        _modification
            ? 'Fiche de ${eleve.nomComplet} mise à jour.'
            : '${eleve.nomComplet} a été ajouté(e).',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      afficherMessage(context, 'L\'enregistrement a échoué.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modification ? 'Modifier l\'élève' : 'Nouvel élève'),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : centrer(
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _matricule,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _erreurMatricule = null,
                      decoration: const InputDecoration(
                        labelText: 'Matricule',
                        helperText: 'Facultatif, mais unique s\'il est saisi',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (_) => _erreurMatricule,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nom,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le nom est obligatoire.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prenoms,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Prénom(s) *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le prénom est obligatoire.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Sexe *',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      emptySelectionAllowed: true,
                      segments: const [
                        ButtonSegment(
                            value: 'F',
                            label: Text('Féminin'),
                            icon: Icon(Icons.female)),
                        ButtonSegment(
                            value: 'M',
                            label: Text('Masculin'),
                            icon: Icon(Icons.male)),
                      ],
                      selected: _sexe == null ? <String>{} : {_sexe!},
                      onSelectionChanged: (s) => setState(() {
                        _sexe = s.isEmpty ? null : s.first;
                        _erreurSexe = null;
                      }),
                    ),
                    if (_erreurSexe != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(_erreurSexe!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12)),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateText,
                      readOnly: true,
                      onTap: _choisirDate,
                      decoration: InputDecoration(
                        labelText: 'Date de naissance',
                        hintText: 'JJ/MM/AAAA',
                        prefixIcon: const Icon(Icons.cake_outlined),
                        border: const OutlineInputBorder(),
                        suffixIcon: _dateIso == null
                            ? const Icon(Icons.calendar_month_outlined)
                            : IconButton(
                                tooltip: 'Effacer la date',
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() {
                                  _dateIso = null;
                                  _dateText.clear();
                                }),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Classe *',
                        prefixIcon: const Icon(Icons.class_outlined),
                        border: const OutlineInputBorder(),
                        errorText: _erreurClasse,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _classeId,
                          hint: const Text('Choisir une classe'),
                          items: [
                            for (final c in _classes)
                              DropdownMenuItem<int>(
                                  value: c.id!, child: Text(c.nom)),
                          ],
                          onChanged: (v) => setState(() {
                            _classeId = v;
                            _erreurClasse = null;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomParent,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nom du parent',
                        prefixIcon: Icon(Icons.family_restroom_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telParent,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone du parent',
                        hintText: 'Ex. : 70 12 34 56',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validerTelephone,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _enCours ? null : _enregistrer,
                      icon: _enCours
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_modification
                          ? 'Enregistrer les modifications'
                          : 'Ajouter l\'élève'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
