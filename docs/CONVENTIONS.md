# Conventions du dépôt

Ce dépôt centralise les travaux pratiques de la matière **Architecture Microservices**. Il est conçu pour accueillir de nouveaux TP sans jamais réorganiser l'existant.

## Règles

- **Nommage** : un dossier par TP, nommé `TP<N>-MS` (`TP5-MS`, `TP6-MS`, ...), directement à la racine.
- **Autonomie** : chaque dossier contient un projet complet (code, `pom.xml`, configuration) qui se compile sans dépendre des autres dossiers.
- **README obligatoire** dans chaque TP, construit à partir de `templates/TP-README.md`.
- **Source de vérité** : `scripts/tps.json` liste les TP (numéro, titre, technologies, dépôt d'origine éventuel). L'index et l'arborescence du README principal en sont générés : ne pas les modifier à la main (blocs entre `<!-- TP-...:START/END -->`).
- **TP1 à TP5** sont des copies fidèles des dépôts d'origine (historique Git inclus) : leur contenu n'est pas modifié ici.

## Ajouter un nouveau TP

1. Créer le dossier et son README, et mettre l'index à jour :

        powershell -ExecutionPolicy Bypass -File .\scripts\new-tp.ps1 -Numero 5 -Titre "Titre du TP" -Tech "Java, Spring Boot"

2. Copier le projet dans `TP5-MS/` et compléter son README.
3. Valider et publier :

        git add -A
        git commit -m "feat(TP5-MS): ajout du TP5"
        git push

## Modifier le titre ou les technologies d'un TP

Éditer l'entrée correspondante dans `scripts/tps.json`, puis relancer :

    powershell -ExecutionPolicy Bypass -File .\scripts\update-readme.ps1

## Messages de commit

`feat(TP<N>-MS): ...` pour un ajout, `fix(TP<N>-MS): ...` pour une correction, `docs: ...` pour la documentation générale, `chore: ...` pour le reste.