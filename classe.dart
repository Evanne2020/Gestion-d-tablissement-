class Classe {
  final int? id;
  final String nom;
  final String anneeScolaire;

  const Classe({this.id, required this.nom, required this.anneeScolaire});

  factory Classe.fromMap(Map<String, Object?> m) => Classe(
        id: m['id'] as int?,
        nom: m['nom'] as String,
        anneeScolaire: m['annee_scolaire'] as String,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'nom': nom,
        'annee_scolaire': anneeScolaire,
      };
}

/// Une classe avec son effectif (et la répartition filles / garçons).
class ClasseAvecEffectif {
  final Classe classe;
  final int effectif;
  final int filles;
  final int garcons;

  const ClasseAvecEffectif({
    required this.classe,
    required this.effectif,
    required this.filles,
    required this.garcons,
  });

  factory ClasseAvecEffectif.fromMap(Map<String, Object?> m) =>
      ClasseAvecEffectif(
        classe: Classe.fromMap(m),
        effectif: (m['effectif'] as num).toInt(),
        filles: (m['filles'] as num).toInt(),
        garcons: (m['garcons'] as num).toInt(),
      );
}
