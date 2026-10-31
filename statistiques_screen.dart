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
import '../widgets/selecteur_periode.dart';
import 'eleve_historique_screen.dart';

/// Statistiques d'absences et de retards par classe et par période.
class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  final _repo = PresenceRepository();

  String _annee = '';
  List<Classe> _classes = [];
  List<StatsEleve> _stats = [];
  List<StatMotif> _motifs = [];
  int? _classeId;
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
      _classes = await ClasseRepository().lister(_annee);
      _periode = Periode.calculer(TypePeriode.mois, annee: _annee);
      await _recharger();
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
      afficherMessage(context, 'Chargement impossible.', erreur: true);
    }
  }

  Future<void> _recharger() async {
    final p = _periode!;
    final stats = await _repo.statsParEleve(
        annee: _annee, du: p.du, au: p.au, classeId: _classeId);
    final motifs = await _repo.statsParMotif(
        annee: _annee, du: p.du, au: p.au, classeId: _classeId);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _motifs = motifs;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: _chargement || _periode == null
          ? const Center(child: CircularProgressIndicator())
          : centrer(_contenu()),
    );
  }

  Widget _contenu() {
    final absences = _stats.fold<int>(0, (s, x) => s + x.nbAbsences);
    final heures = _stats.fold<double>(0, (s, x) => s + x.heuresAbsence);
    final justifiees = _stats.fold<int>(0, (s, x) => s + x.absencesJustifiees);
    final retards = _stats.fold<int>(0, (s, x) => s + x.nbRetards);

    final concernes = _stats
        .where((s) => s.nbAbsences + s.nbRetards > 0)
        .toList()
      ..sort((a, b) {
        final c = b.heuresAbsence.compareTo(a.heuresAbsence);
        if (c != 0) return c;
        final r = b.nbRetards.compareTo(a.nbRetards);
        if (r != 0) return r;
        return a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase());
      });

    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chiffre('Absences', '$absences', Colors.red.shade700),
            _chiffre('Heures d\'absence', formatHeures(heures), Colors.red.shade700),
            _chiffre('Abs. justifiées', '$justifiees', Colors.green.shade700),
            _chiffre('Abs. non justifiées', '${absences - justifiees}',
                Colors.orange.shade800),
            _chiffre('Retards', '$retards', Colors.blue.shade700),
          ],
        ),
        const SizedBox(height: 16),
        Text('Motifs les plus fréquents',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (_motifs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune donnée sur cette période.'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final m in _motifs)
                  ListTile(
                    dense: true,
                    title: Text(m.motif),
                    trailing: Text('${m.nombre}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text('Élèves concernés (${concernes.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (concernes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun élève absent ou en retard sur cette période.'),
          )
        else
          for (final s in concernes)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EleveHistoriqueScreen(eleveId: s.eleveId)),
                ).then((_) => _recharger()),
                title: Text(s.nomComplet,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${s.classeNom}\n'
                  '${s.nbAbsences} absence(s) (${formatHeures(s.heuresAbsence)}, '
                  '${s.absencesNonJustifiees} non justifiée(s)) · '
                  '${s.nbRetards} retard(s)',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
      ],
    );
  }

  Widget _chiffre(String libelle, String valeur, Color couleur) {
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
