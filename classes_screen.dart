import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/classe.dart';
import '../repositories/classe_repository.dart';
import '../repositories/parametre_repository.dart';
import 'eleves_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _repo = ClasseRepository();
  final _params = ParametreRepository();

  String _annee = '';
  List<ClasseAvecEffectif> _liste = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final annee = await _params.anneeScolaire();
      final liste = await _repo.listerAvecEffectif(annee);
      if (!mounted) return;
      setState(() {
        _annee = annee;
        _liste = liste;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Impossible de charger les classes.',
          erreur: true);
    }
  }

  Future<void> _ajouter() async {
    final nom = await showDialog<String>(
      context: context,
      builder: (_) => _ClasseDialog(
        titre: 'Nouvelle classe',
        existe: (n) => _repo.existe(n, _annee),
      ),
    );
    if (nom == null) return;
    try {
      await _repo.ajouter(Classe(nom: nom, anneeScolaire: _annee));
      if (!mounted) return;
      afficherMessage(context, 'Classe « $nom » ajoutée.');
      _charger();
    } catch (e) {
      if (!mounted) return;
      afficherMessage(context, 'L\'ajout a échoué.', erreur: true);
    }
  }

  Future<void> _modifier(ClasseAvecEffectif c) async {
    final nom = await showDialog<String>(
      context: context,
      builder: (_) => _ClasseDialog(
        titre: 'Modifier la classe',
        nomInitial: c.classe.nom,
        existe: (n) => _repo.existe(n, _annee, exceptId: c.classe.id),
      ),
    );
    if (nom == null || nom == c.classe.nom) return;
    try {
      await _repo.modifier(
          Classe(id: c.classe.id, nom: nom, anneeScolaire: _annee));
      if (!mounted) return;
      afficherMessage(context, 'Classe renommée en « $nom ».');
      _charger();
    } catch (e) {
      if (!mounted) return;
      afficherMessage(context, 'La modification a échoué.', erreur: true);
    }
  }

  Future<void> _supprimer(ClasseAvecEffectif c) async {
    if (c.effectif == 0) {
      final ok = await confirmer(
        context,
        titre: 'Supprimer « ${c.classe.nom} » ?',
        message: 'Cette classe est vide. Cette action est irréversible.',
      );
      if (!ok) return;
      await _executer(
        () => _repo.supprimer(c.classe.id!),
        succes: 'Classe « ${c.classe.nom} » supprimée.',
      );
      return;
    }

    // Classe non vide : les élèves sont protégés. Il faut les transférer.
    final autres =
        _liste.where((x) => x.classe.id != c.classe.id).toList();
    final destination = await showDialog<ClasseAvecEffectif>(
      context: context,
      builder: (_) => _TransfertDialog(source: c, autres: autres),
    );
    if (destination == null) return;
    await _executer(
      () async {
        await _repo.transfererEtSupprimer(
            c.classe.id!, destination.classe.id!);
      },
      succes: '${c.effectif} élève(s) transféré(s) vers '
          '« ${destination.classe.nom} ». Classe « ${c.classe.nom} » supprimée.',
    );
  }

  /// Exécute une opération de suppression et affiche le résultat.
  Future<void> _executer(Future<void> Function() action,
      {required String succes}) async {
    try {
      await action();
      if (!mounted) return;
      afficherMessage(context, succes);
    } on ClasseNonVideException catch (e) {
      if (!mounted) return;
      afficherMessage(
          context,
          'Suppression refusée : la classe contient encore ${e.effectif} '
          'élève(s).',
          erreur: true);
    } catch (_) {
      if (!mounted) return;
      afficherMessage(context, 'La suppression a échoué.', erreur: true);
    }
    _charger();
  }

  Future<void> _ouvrirEleves(ClasseAvecEffectif c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ElevesScreen(classeIdInitial: c.classe.id)),
    );
    _charger(); // l'effectif a pu changer
  }

  @override
  Widget build(BuildContext context) {
    final total = _liste.fold<int>(0, (s, c) => s + c.effectif);
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: _chargement
          ? null
          : FloatingActionButton.extended(
              onPressed: _ajouter,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle classe'),
            ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : centrer(
              _liste.isEmpty
                  ? _VideClasses(onAjouter: _ajouter)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        Text(
                          'Année scolaire $_annee · ${_liste.length} classe(s) · '
                          '$total élève(s)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        for (final c in _liste) _carte(c),
                      ],
                    ),
            ),
    );
  }

  Widget _carte(ClasseAvecEffectif c) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          child: Text('${c.effectif}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(c.classe.nom,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        subtitle: Text(
          '${c.effectif} élève(s) · ${c.filles} fille(s) · ${c.garcons} garçon(s)',
        ),
        onTap: () => _ouvrirEleves(c),
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (v) => v == 'modifier' ? _modifier(c) : _supprimer(c),
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

class _VideClasses extends StatelessWidget {
  final VoidCallback onAjouter;
  const _VideClasses({required this.onAjouter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.class_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('Aucune classe pour le moment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Créez votre première classe pour commencer.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAjouter,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle classe'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boîte de dialogue d'ajout / modification d'une classe.
class _ClasseDialog extends StatefulWidget {
  final String titre;
  final String? nomInitial;
  final Future<bool> Function(String nom) existe;

  const _ClasseDialog({
    required this.titre,
    required this.existe,
    this.nomInitial,
  });

  @override
  State<_ClasseDialog> createState() => _ClasseDialogState();
}

class _ClasseDialogState extends State<_ClasseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;
  String? _erreurDoublon;

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

  Future<void> _valider() async {
    final nom = _ctrl.text.trim();
    _erreurDoublon = null;
    if (nom.isNotEmpty && await widget.existe(nom)) {
      _erreurDoublon = 'Cette classe existe déjà.';
    }
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, nom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _valider(),
          decoration: const InputDecoration(
            labelText: 'Nom de la classe',
            hintText: 'Ex. : 6e A, Terminale D',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Saisissez le nom de la classe.';
            }
            return _erreurDoublon;
          },
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

/// Dialogue affiché quand on veut supprimer une classe qui contient des élèves.
/// Retourne la classe de destination choisie, ou null si l'utilisateur annule.
class _TransfertDialog extends StatefulWidget {
  final ClasseAvecEffectif source;
  final List<ClasseAvecEffectif> autres;
  const _TransfertDialog({required this.source, required this.autres});

  @override
  State<_TransfertDialog> createState() => _TransfertDialogState();
}

class _TransfertDialogState extends State<_TransfertDialog> {
  ClasseAvecEffectif? _choix;

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final peutTransferer = widget.autres.isNotEmpty;
    return AlertDialog(
      icon: const Icon(Icons.shield_outlined),
      title: Text('« ${s.classe.nom} » n\'est pas vide'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette classe contient ${s.effectif} élève(s). Pour les '
              'protéger, elle ne peut pas être supprimée tant qu\'elle n\'est '
              'pas vide.',
            ),
            const SizedBox(height: 12),
            if (!peutTransferer)
              const Text(
                'Créez d\'abord une autre classe pour y transférer les élèves, '
                'ou déplacez-les un par un depuis leur fiche.',
              )
            else ...[
              const Text('Transférer tous les élèves vers :'),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Classe de destination',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClasseAvecEffectif>(
                    isExpanded: true,
                    value: _choix,
                    hint: const Text('Choisir une classe'),
                    items: [
                      for (final c in widget.autres)
                        DropdownMenuItem(
                          value: c,
                          child: Text('${c.classe.nom} (${c.effectif})'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _choix = v),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        if (peutTransferer)
          FilledButton(
            onPressed:
                _choix == null ? null : () => Navigator.pop(context, _choix),
            child: const Text('Transférer et supprimer'),
          ),
      ],
    );
  }
}
