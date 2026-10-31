class Eleve {
  final int? id;
  final String? matricule;
  final String nom;
  final String prenoms;
  final String sexe; // 'F' ou 'M'
  final String? dateNaissance; // AAAA-MM-JJ
  final String? lieuNaissance; // pas encore utilisé dans l'interface
  final String? telephone; // pas encore utilisé dans l'interface
  final String? nomParent;
  final String? telephoneParent;
  final int classeId;

  /// Rempli uniquement par les requêtes avec jointure (non enregistré).
  final String? classeNom;

  const Eleve({
    this.id,
    this.matricule,
    required this.nom,
    required this.prenoms,
    required this.sexe,
    this.dateNaissance,
    this.lieuNaissance,
    this.telephone,
    this.nomParent,
    this.telephoneParent,
    required this.classeId,
    this.classeNom,
  });

  String get nomComplet => '$nom $prenoms';

  factory Eleve.fromMap(Map<String, Object?> m) => Eleve(
        id: m['id'] as int?,
        matricule: m['matricule'] as String?,
        nom: m['nom'] as String,
        prenoms: m['prenoms'] as String,
        sexe: m['sexe'] as String,
        dateNaissance: m['date_naissance'] as String?,
        lieuNaissance: m['lieu_naissance'] as String?,
        telephone: m['telephone'] as String?,
        nomParent: m['nom_parent'] as String?,
        telephoneParent: m['telephone_parent'] as String?,
        classeId: m['classe_id'] as int,
        classeNom: m['classe_nom'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'matricule': matricule,
        'nom': nom,
        'prenoms': prenoms,
        'sexe': sexe,
        'date_naissance': dateNaissance,
        'lieu_naissance': lieuNaissance,
        'telephone': telephone,
        'nom_parent': nomParent,
        'telephone_parent': telephoneParent,
        'classe_id': classeId,
      };
}
