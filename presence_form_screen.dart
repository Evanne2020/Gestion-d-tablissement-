import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../core/utils.dart';
import '../models/classe.dart';
import '../models/eleve.dart';
import '../models/presence.dart';
import '../repositories/classe_repository.dart';
import '../repositories/eleve_repository.dart';
import '../repositories/parametre_repository.dart';
import '../repositories/presence_repository.dart';
import '../widgets/choix_eleve.dart';

/// Saisie / modification d'une absence ou d'un retard.
/// - [type] : Presence.absence ou Presence.retard
/// - [presence] : enregistrement à modifier (élève non modifiable)
/// - [eleve] : élève déjà connu (lancé depuis sa fiche ou son historique)
/// Retourne `true` si quelque chose a été enregistré.
class PresenceFormScreen extends StatefulWidget {
  final String type;
  final Presence? presence;
  final Eleve? eleve;
  final int? classeIdParDefaut;

  const PresenceFormScreen({
    super.key,
    required this.type,
    this.presence,
    this.eleve,
    this.classeIdParDefaut,
  });

  @override
  State<PresenceFormScreen> createState() => _PresenceFormScreenState();
}

class _PresenceFormScreenState extends State<PresenceFormScreen> {
  static const _motifsFrequents = [
    'Maladie',
    'Événement familial',
    'Transport',
    'Rendez-vous médical',
  ];

  final _formKey = GlobalKey<FormState>();
  final _repo = PresenceRepository();
  final _heuresCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();

  String _annee = '';
  List<Classe> _classes = [];
  List<Eleve> _elevesClasse = [];
  int? _classeId;
  int? _eleveId;
  String? _eleveNom;
  String? _classeNom;

  late DateTime _date;
  TimeOfDay? _heureArrivee;
  bool _justifie = false;

  String? _erreurEleve;
  String? _erreurHeure;
  bool _chargement = true;
  bool _enCours = false;

  bool get _absence => widget.type == Presence.absence;
  bool get _modification => widget.presence != null;
  bool get _verrouille => widget.presence != null || widget.eleve != null;

  @override
  void initState() {
    super.initState();
    final p = widget.presence;
    final n = DateTime.now();
    _date = DateTime.tryParse(p?.date ?? '') ?? DateTime(n.year, n.month, n.day);
    if (p != null) {
      _eleveId = p.eleveId;
      _eleveNom = p.eleveNomComplet;
      _classeNom = p.classeNom;
      _justifie = p.justifie;
      _motifCtrl.text = p.motif ?? '';
      if (p.estAbsence) {
        _heuresCtrl.text = p.heures.toString().replaceAll('.', ',').replaceAll(RegExp(r',0$'), '');
      } else if (p.heureArrivee != null) {
        final parts = p.heureArrivee!.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) _heureArrivee = TimeOfDay(hour: h, minute: m);
        }
      }
    } else if (widget.eleve != null) {
      _eleveId = widget.eleve!.id;
      _eleveNom = widget.eleve!.nomComplet;
      _classeNom = widget.eleve!.classeNom;
    } else {
      _classeId = widget.classeIdParDefaut;
    }
    _init();
  }

  @override
  void dispose() {
    _heuresCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _annee = await ParametreRepository().anneeScolaire();
      if (!_verrouille) {
        _classes = await ClasseRepository().lister(_annee);
        if (_classeId != null && !_classes.any((c) => c.id == _classeId)) {
          _classeId = null;
        }
        if (_classeId != null) await _chargerEleves(_classeId!);
      }
      if (!mounted) return;
      setState(() => _chargement = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Chargement impossible.', erreur: true);
    }
  }

  Future<void> _chargerEleves(int classeId) async {
    _elevesClasse =
        await EleveRepository().rechercher(annee: _annee, classeId: classeId);
  }

  Future<void> _changerClasse(int? id) async {
    setState(() {
      _classeId = id;
      _eleveId = null;
      _eleveNom = null;
      _elevesClasse = [];
    });
    if (id == null) return;
    try {
      await _chargerEleves(id);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'Impossible de charger les élèves.',
          erreur: true);
    }
  }

  Future<void> _choisirEleve() async {
    if (_classeId == null) {
      setState(() => _erreurEleve = 'Choisissez d\'abord une classe.');
      return;
    }
    if (_elevesClasse.isEmpty) {
      afficherMessage(context, 'Cette classe ne contient aucun élève.',
          erreur: true);
      return;
    }
    final e = await choisirEleve(context, _elevesClasse);
    if (e == null) return;
    setState(() {
      _eleveId = e.id;
      _eleveNom = e.nomComplet;
      _erreurEleve = null;
    });
  }

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: _absence ? 'Date de l\'absence' : 'Date du retard',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _choisirHeure() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _heureArrivee ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Heure d\'arrivée',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        _heureArrivee = t;
        _erreurHeure = null;
      });
    }
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  double? _lireHeures() =>
      double.tryParse(_heuresCtrl.text.trim().replaceAll(',', '.'));

  Future<void> _enregistrer() async {
    if (_enCours) return;
    final valide = _formKey.currentState!.validate();
    setState(() {
      _erreurEleve = _eleveId == null ? 'Choisissez un élève.' : null;
      _erreurHeure =
          (!_absence && _heureArrivee == null) ? 'Indiquez l\'heure d\'arrivée.' : null;
    });
    if (!valide || _eleveId == null || (!_absence && _heureArrivee == null)) {
      return;
    }

    final dateIso = toIsoDate(_date);
    setState(() => _enCours = true);
    try {
      if (await _repo.existe(
        eleveId: _eleveId!,
        date: dateIso,
        type: widget.type,
        exceptId: widget.presence?.id,
      )) {
        if (!mounted) return;
        setState(() => _enCours = false);
        afficherMessage(
          context,
          _absence
              ? 'Une absence est déjà enregistrée pour cet élève à cette date. '
                  'Modifiez-la au lieu d\'en créer une seconde.'
              : 'Un retard est déjà enregistré pour cet élève à cette date. '
                  'Modifiez-le au lieu d\'en créer un second.',
          erreur: true,
        );
        return;
      }

      final p = Presence(
        id: widget.presence?.id,
        eleveId: _eleveId!,
        date: dateIso,
        type: widget.type,
        heures: _absence ? _lireHeures()! : 0,
        heureArrivee: _absence ? null : _hhmm(_heureArrivee!),
        motif: nullSiVide(_motifCtrl.text),
        justifie: _justifie,
      );
      if (_modification) {
        await _repo.modifier(p);
      } else {
        await _repo.ajouter(p);
      }
      if (!mounted) return;
      afficherMessage(
        context,
        _modification
            ? 'Modification enregistrée.'
            : '${_absence ? 'Absence' : 'Retard'} enregistré(e) pour $_eleveNom.',
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      afficherMessage(context, 'L\'enregistrement a échoué.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titre = _modification
        ? (_absence ? 'Modifier l\'absence' : 'Modifier le retard')
        : (_absence ? 'Nouvelle absence' : 'Nouveau retard');
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : centrer(
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._blocEleve(),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey(_date),
                      initialValue: formatDateFr(toIsoDate(_date)),
                      readOnly: true,
                      onTap: _choisirDate,
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        prefixIcon: Icon(Icons.event_outlined),
                        suffixIcon: Icon(Icons.calendar_month_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_absence) ..._blocHeures() else ..._blocArrivee(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _motifCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Motif',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final m in _motifsFrequents)
                          ActionChip(
                            label: Text(m),
                            onPressed: () =>
                                setState(() => _motifCtrl.text = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_absence
                          ? 'Absence justifiée'
                          : 'Retard justifié'),
                      subtitle: const Text('Un justificatif a été présenté'),
                      value: _justifie,
                      onChanged: (v) => setState(() => _justifie = v),
                    ),
                    const SizedBox(height: 16),
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
                          : 'Enregistrer'),
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

  List<Widget> _blocEleve() {
    if (_verrouille) {
      return [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(_eleveNom ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: _classeNom == null ? null : Text(_classeNom!),
          ),
        ),
      ];
    }
    return [
      InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Classe *',
          prefixIcon: Icon(Icons.class_outlined),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: _classeId,
            hint: const Text('Choisir une classe'),
            items: [
              for (final c in _classes)
                DropdownMenuItem<int>(value: c.id!, child: Text(c.nom)),
            ],
            onChanged: _changerClasse,
          ),
        ),
      ),
      const SizedBox(height: 16),
      InkWell(
        onTap: _choisirEleve,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Élève *',
            prefixIcon: const Icon(Icons.person_outline),
            suffixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            errorText: _erreurEleve,
          ),
          child: Text(_eleveNom ?? 'Choisir un élève'),
        ),
      ),
    ];
  }

  List<Widget> _blocHeures() => [
        TextFormField(
          controller: _heuresCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nombre d\'heures d\'absence *',
            hintText: 'Ex. : 2 ou 1,5',
            prefixIcon: Icon(Icons.timer_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            final h = _lireHeures();
            if (h == null) return 'Saisissez un nombre d\'heures.';
            if (h <= 0 || h > 24) return 'Entre 0 et 24 heures.';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final h in const ['1', '2', '4', '8'])
              ActionChip(
                label: Text('$h h'),
                onPressed: () => setState(() => _heuresCtrl.text = h),
              ),
          ],
        ),
      ];

  List<Widget> _blocArrivee() => [
        InkWell(
          onTap: _choisirHeure,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Heure d\'arrivée *',
              prefixIcon: const Icon(Icons.schedule),
              suffixIcon: const Icon(Icons.access_time),
              border: const OutlineInputBorder(),
              errorText: _erreurHeure,
            ),
            child: Text(
                _heureArrivee == null ? 'Choisir l\'heure' : _hhmm(_heureArrivee!)),
          ),
        ),
      ];
}
