/// Une absence ou un retard d'un élève.
class Presence {
  static const absence = 'absence';
  static const retard = 'retard';

  final int? id;
  final int eleveId;
  final String date; // AAAA-MM-JJ
  final String type; // 'absence' ou 'retard'
  final double heures; // heures d'absence (0 pour un retard)
  final String? heureArrivee; // HH:mm, pour un retard
  final String? motif;
  final bool justifie;

  // Renseignés seulement par les requêtes avec jointure (non enregistrés)
  final String? eleveNom;
  final String? elevePrenoms;
  final String? eleveSexe;
  final int? classeId;
  final String? classeNom;

  const Presence({
    this.id,
    required this.eleveId,
    required this.date,
    required this.type,
    this.heures = 0,
    this.heureArrivee,
    this.motif,
    this.justifie = false,
    this.eleveNom,
    this.elevePrenoms,
    this.eleveSexe,
    this.classeId,
    this.classeNom,
  });

  bool get estAbsence => type == absence;

  String get eleveNomComplet =>
      '${eleveNom ?? ''} ${elevePrenoms ?? ''}'.trim();

  factory Presence.fromMap(Map<String, Object?> m) => Presence(
        id: m['id'] as int?,
        eleveId: m['eleve_id'] as int,
        date: m['date'] as String,
        type: m['type'] as String,
        heures: (m['heures'] as num?)?.toDouble() ?? 0,
        heureArrivee: m['heure_arrivee'] as String?,
        motif: m['motif'] as String?,
        justifie: (m['justifie'] as num?)?.toInt() == 1,
        eleveNom: m['eleve_nom'] as String?,
        elevePrenoms: m['eleve_prenoms'] as String?,
        eleveSexe: m['eleve_sexe'] as String?,
        classeId: m['classe_id'] as int?,
        classeNom: m['classe_nom'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'eleve_id': eleveId,
        'date': date,
        'type': type,
        'heures': heures,
        'heure_arrivee': heureArrivee,
        'motif': motif,
        'justifie': justifie ? 1 : 0,
      };
}

/// Totaux d'un élève sur une période.
class StatsEleve {
  final int eleveId;
  final String nom;
  final String prenoms;
  final String sexe;
  final String classeNom;
  final int nbAbsences;
  final double heuresAbsence;
  final int absencesJustifiees;
  final int nbRetards;
  final int retardsJustifies;

  const StatsEleve({
    required this.eleveId,
    required this.nom,
    required this.prenoms,
    required this.sexe,
    required this.classeNom,
    required this.nbAbsences,
    required this.heuresAbsence,
    required this.absencesJustifiees,
    required this.nbRetards,
    required this.retardsJustifies,
  });

  String get nomComplet => '$nom $prenoms';
  int get absencesNonJustifiees => nbAbsences - absencesJustifiees;
  int get retardsNonJustifies => nbRetards - retardsJustifies;

  factory StatsEleve.fromMap(Map<String, Object?> m) => StatsEleve(
        eleveId: m['id'] as int,
        nom: m['nom'] as String,
        prenoms: m['prenoms'] as String,
        sexe: m['sexe'] as String,
        classeNom: m['classe_nom'] as String,
        nbAbsences: (m['nb_absences'] as num).toInt(),
        heuresAbsence: (m['heures_absence'] as num).toDouble(),
        absencesJustifiees: (m['abs_justifiees'] as num).toInt(),
        nbRetards: (m['nb_retards'] as num).toInt(),
        retardsJustifies: (m['retards_justifies'] as num).toInt(),
      );
}

class StatMotif {
  final String motif;
  final int nombre;
  const StatMotif(this.motif, this.nombre);
}
