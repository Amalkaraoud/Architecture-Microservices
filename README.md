# Architecture Microservices

Dépôt centralisé regroupant l'ensemble des travaux pratiques de la matière **Architecture Microservices**. Chaque TP est un projet autonome, dans son propre dossier, accompagné de son README détaillé.

> Les TP1 à TP4 existent aussi dans leurs dépôts d'origine (liens dans l'index), qui restent inchangés. Les TP suivants sont publiés uniquement ici.

## Index des TP

<!-- TP-INDEX:START -->
| TP | Thème | Technologies | Dépôt d'origine |
|----|-------|--------------|-----------------|
| [TP1-MS](./TP1-MS) | Inversion de Contrôle et Injection de Dépendances | Java, Maven, Spring | [Amalkaraoud/TP1-MS](https://github.com/Amalkaraoud/TP1-MS) |
| [TP2-MS](./TP2-MS) | REST : service web « Calculatrice » avec JAX-RS et Tomcat | Java, JAX-RS, Tomcat | [Amalkaraoud/TP2-MS](https://github.com/Amalkaraoud/TP2-MS) |
| [TP3-MS](./TP3-MS) | REST : microservice « Calculatrice » avec Spring Boot | Java, Spring Boot | [Amalkaraoud/TP3-MS](https://github.com/Amalkaraoud/TP3-MS) |
| [TP4-MS](./TP4-MS) | Spring Cloud : « Calculatrice » avec Eureka, Gateway et OpenFeign | Java, Spring Cloud, Eureka, Gateway, OpenFeign | [Amalkaraoud/TP4-MS](https://github.com/Amalkaraoud/TP4-MS) |
<!-- TP-INDEX:END -->

Cliquer sur le nom d'un TP pour accéder à son dossier et à son README.

## Structure du dépôt

<!-- TP-TREE:START -->
    Architecture-Microservices/
    ├── README.md
    ├── TP1-MS/
    ├── TP2-MS/
    ├── TP3-MS/
    ├── TP4-MS/
    ├── docs/
    ├── scripts/
    └── templates/
<!-- TP-TREE:END -->

Chaque dossier `TP<N>-MS` est autonome : il se compile et s'exécute indépendamment des autres.

## Ajouter un nouveau TP

    powershell -ExecutionPolicy Bypass -File .\scripts\new-tp.ps1 -Numero 5 -Titre "Titre du TP" -Tech "Java, Spring Boot"

Le script crée le dossier et son README (depuis `templates/TP-README.md`), puis met à jour l'index ci-dessus. Détails : [docs/CONVENTIONS.md](./docs/CONVENTIONS.md).

## Utilisation

    git clone https://github.com/Amalkaraoud/Architecture-Microservices.git
    cd Architecture-Microservices/TP1-MS

Les instructions de compilation et d'exécution se trouvent dans le README de chaque TP.

## Auteur

Amal Karaoud — [github.com/Amalkaraoud](https://github.com/Amalkaraoud)