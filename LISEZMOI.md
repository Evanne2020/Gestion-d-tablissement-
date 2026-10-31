# GEST-ÉTAB — Étapes 1 à 4a
# Code NON compilé ni testé sur Flutter par l'auteur.

Prérequis : Flutter >= 3.27 (Dart >= 3.6).

1. flutter create --platforms=android,windows gest_etab
2. Remplacer pubspec.yaml, lib/, test/ et assets/ par ceux de ce zip
3. Supprimer test/widget_test.dart (généré par défaut, il référence MyApp)
4. flutter pub get            (Internet nécessaire ici, pour télécharger les paquets)
5. Android 11+ : dans android/app/build.gradle(.kts) mettre minSdk = 30
6. flutter analyze            (doit afficher « No issues found »)
7. flutter test
8. flutter run -d windows   (ou -d <appareil android>)

Notes :
- Le 1er build Windows télécharge PDFium (impression) : Internet requis ce jour-là
  sur le PC de développement. L'application finale n'utilise jamais Internet.
- Police des PDF : Liberation Sans (licence SIL OFL, voir assets/fonts/).
- Base de données : aucune migration (la table `parametres` est clé/valeur).
