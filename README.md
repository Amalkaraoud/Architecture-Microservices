# TP5 — Configuration centralisée de la « Calculatrice » avec Spring Cloud Config

| | |
|---|---|
| **Établissement** | Faculté des Sciences de Sfax — Département d'informatique et des Communications |
| **Matière** | Architecture MicroServices — filière MPSRCC1 |
| **Enseignantes** | Corinne Amel ZAYANI, Amal ABID |
| **Année universitaire** | 2026-2027 |
| **Base** | Projet du TP4 (`calculatrice-spring-cloud`), étendu sans régression |

## 1. Ce qui a été ajouté au TP4

| Élément | Nature | Fichiers |
|---|---|---|
| `config-service` (port 9999) | nouveau module Maven, `@EnableConfigServer`, s'inscrit dans Eureka | `config-service/` + ligne `<module>` du `pom.xml` racine |
| Dépôt de configuration | dossier Git voisin `calculatrice-config-repo`, sept fichiers `.properties` | archive `calculatrice-config-repo.zip` à la racine du projet |
| Client de configuration | dépendances `spring-cloud-starter-config` et `spring-boot-starter-actuator`, `spring.config.import`, réglages communs retirés des fichiers locaux | `calcul-service` et `historique-service` (`pom.xml`, `application.properties`) |
| `calcul-service` | `ConfigController` (`GET /calcul/config`), `@RefreshScope` et limite `calcul.max-operande` dans `CalculController` | `calcul-service/src/main/java/.../controller/` |
| `historique-service` | `HistoriqueParams` (`@ConfigurationProperties`), `HistoriqueConfigController` (`GET /operations/config`), limite `historique.max-operations` (409) dans `OperationController` | `historique-service/src/main/java/.../` |
| `eureka-service`, `gateway-service` | inchangés | — |

Structure du travail rendu : le projet `calculatrice-spring-cloud` (cinq modules), l'archive du dépôt de configuration avec son dossier `.git`, ce README et les captures d'écran.

## 2. Réponses aux questions

### Partie A

**A.4-1.** `spring.config.import` doit être connue avant que le microservice ne démarre : la configuration est lue pendant la préparation de l'environnement, avant la création des beans, donc avant que le client Eureka existe. L'annuaire ne peut donc pas fournir cette adresse. De plus, les réglages Eureka eux-mêmes viennent du serveur de configuration : le serveur doit être joignable par une adresse connue d'avance.

**A.4-2.** Les calculs continuent : chaque microservice a lu sa configuration au démarrage et la garde en mémoire. En revanche, relancer `calcul-service` pendant la panne pose problème : avec `optional:` le démarrage continue sans le serveur, mais `@Value("${calcul.max-operande}")` n'a alors aucune valeur ni valeur par défaut et le démarrage échoue (`Could not resolve placeholder`). Vérification expérimentale : question D.2.

**A.4-3.** L'instance 8081 renvoie la nouvelle valeur, l'instance 8083 renvoie encore l'ancienne. Comme la passerelle répartit les requêtes entre les deux, un client obtient des réponses différentes pour la même requête : les instances d'un même service sont incohérentes entre elles.

### Partie B

**B.1.** L'instance 8081 déclare `calcul-service:8081`, l'instance 8083 déclare `calcul-service:8083`. Le serveur ne remplace pas les `${…}` : chaque microservice les résout lui-même avec ses propres valeurs, `spring.application.name` venant de son `application.properties` local et `server.port` du fichier local (8081) ou de la ligne de commande (`--server.port=8083`).

### Partie C

**C.1.** Le client retient 100, valeur de `calcul-service-dev.properties`, première source de la liste. C'est la règle de priorité 2 du tableau A.2 (dépôt, service + profil) qui l'emporte sur la règle 3 (dépôt, service seul).

**C.2.** Avantage : un service sans fichier dédié démarre quand même avec les propriétés communes, sans erreur. Inconvénient : une faute dans `spring.application.name` n'est signalée par aucune erreur du serveur. Le microservice ne reçoit que les propriétés communes, et l'erreur n'apparaît que plus tard (propriété introuvable, ou valeur par défaut utilisée sans que personne ne le remarque).

### Partie D

**D.1.** Pour `server.port`, `/actuator/env` indiquerait le fichier local `application.properties` du module (8081), ou la ligne de commande pour l'instance 8083. Pour `spring.application.name`, la source est aussi le fichier local : le microservice en a besoin pour demander sa configuration, elle ne peut donc pas venir du serveur.

**D.2.** Résultat attendu (à confirmer par l'expérience, voir §4) : avec `optional:`, le démarrage continue sans le serveur, puis échoue plus loin sur `Could not resolve placeholder 'calcul.max-operande'` au moment de créer `ConfigController`. Sans `optional:`, l'échec survient plus tôt, pendant la préparation de l'environnement, avec un message explicite indiquant que le serveur de configuration est injoignable (fail fast) : plus clair. Conclusion : un microservice dépend de son serveur de configuration au démarrage (pas en fonctionnement), et `optional:` ne supprime pas cette dépendance quand une propriété n'a pas de valeur de repli.

**D.3.** Deux moyens : (1) empêcher la passerelle de publier la route de `config-service` (exclure ce service du `discovery.locator`, ou ne déclarer que des routes statiques explicites), et protéger le serveur par Spring Security (authentification HTTP Basic) ; (2) chiffrer les valeurs sensibles dans le dépôt avec le préfixe `{cipher}` fourni par Spring Cloud Config, de sorte qu'un mot de passe ne soit jamais lisible en clair dans le dépôt.

### Partie E

**E.1.** Le serveur ne garde rien en mémoire : il relit le dépôt à chaque requête. C'est le client qui a une copie figée dans son environnement ; le refresh lui demande de la redemander au serveur.

**E.2.**

| Élément | Relu après `/actuator/refresh` ? |
|---|---|
| `@Value` dans un bean `@RefreshScope` | Oui (bean recréé à la prochaine utilisation) |
| `@Value` dans un bean ordinaire | Non (valeur du démarrage conservée) |
| Attribut d'un bean `@ConfigurationProperties` | Oui (setters rappelés sur le même objet) |

Règle de conception : pour une configuration modifiable à chaud, la placer dans un bean `@ConfigurationProperties` (ou dans un bean `@RefreshScope`) et ne jamais lire ces propriétés par `@Value` dans un bean ordinaire.

**E.3.** Résultat à observer (voir §4). Dans l'énoncé, ce que lit le serveur sur un dépôt local `file:///` et le rôle du commit sont l'objet de l'expérience ; avec une URL distante (`https://…`), le serveur clone le dépôt et ne verrait que ce qui a été commité **et poussé**, ce qui n'est pas le comportement d'un dossier local.

### Partie F

**F.1.** Elles viennent de `application.properties` du dépôt, que le serveur ajoute toujours en dernière source pour tout service. Il ne fallait pas les recopier dans le fichier `-prod` : ce fichier ne contient que ce qui diffère du cas général.

**F.2.** Créer à la racine du dépôt `application-prod.properties` avec `eureka.instance.lease-renewal-interval-in-seconds=30` (et `eureka.instance.lease-expiration-duration-in-seconds=90`, valeur par défaut), puis le commiter. Ce fichier ne s'applique qu'aux services lancés en profil `prod` et l'emporte sur `application.properties`.

## 3. Questions de synthèse

1. **Tableau A.3** : nombre de programmes → C.5 / D.6 (six consoles, Eureka) ; dépendances → D.1 et D.5 ; emplacement des propriétés → D.2 ; réglages communs → B.1 puis D.2 ; changer une valeur → E.1 et E.2 ; environnements → F.1 à F.3 ; historique → `git log` (B.2, E.1, E.3) et champ `version` (C.5) ; lecture en Java → D.3 et D.5 ; points Actuator → D.4 et E.2 ; ordre de lancement → prérequis et C.5.
2. **Démarrage d'`historique-service` en profil `dev`** : (1) lecture de son `application.properties` local (nom, port 8082, `spring.config.import`, URL Eureka) ; (2) `GET http://localhost:9999/historique-service/dev` vers `config-service` ; (3) le serveur lit dans le dépôt, dans cet ordre, `historique-service-dev.properties`, `historique-service.properties`, `application.properties` ; (4) réponse JSON, les trois sources sont ajoutées devant le fichier local ; `historique.max-operations` vaut 3 (fichier `-dev`, qui l'emporte sur 50) ; (5) création des beans, inscription dans Eureka (`GET/POST` vers 8761), Tomcat démarre sur 8082.
3. **Les trois propriétés locales** : `spring.application.name` (c'est le `{nom}` envoyé au serveur), `spring.config.import` (l'adresse du serveur doit être connue pour lui parler), `server.port` (deux instances du même service ont le même nom mais des ports différents).
4. **`optional:`** : avantage, le microservice démarre même si le serveur est en panne ; inconvénient, il peut démarrer avec une configuration incomplète ou par défaut sans que l'erreur soit visible tout de suite. En production, on choisirait de ne pas mettre `optional:` (fail fast) pour ne jamais tourner avec une mauvaise configuration.
5. **Spring Cloud Bus** introduit un bus de messages (broker RabbitMQ ou Kafka) auquel toutes les instances sont abonnées. Le point `/actuator/busrefresh` remplace `/actuator/refresh` : un seul appel diffuse l'ordre de rechargement à toutes les instances.
6. **`@Value` + `@RefreshScope` / `@ConfigurationProperties`** : `@Value` est simple pour une ou deux propriétés mais éparpille les clés ; `@ConfigurationProperties` regroupe un préfixe dans une classe et convertit les types avec le relaxed binding (valeurs manquantes tolérées). Au refresh, `@Value` exige `@RefreshScope` (bean recréé), alors que `@ConfigurationProperties` est re-lié automatiquement. On préfère `@Value` pour une valeur isolée, `@ConfigurationProperties` dès qu'on a un groupe de propriétés.
7. **Chiffrement** : une valeur est écrite `{cipher}…` dans le dépôt, produite par `POST /encrypt` (le déchiffrement : `POST /decrypt`). La clé (`encrypt.key` ou keystore) est détenue par le serveur de configuration ; par défaut, la valeur est déchiffrée par le serveur au moment de servir la configuration au client.
8. **Passerelle cliente** : ajouter `spring-cloud-starter-config` au `pom.xml`, `spring.config.import: optional:configserver:http://localhost:9999` dans `application.yml` (en gardant nom et port), et créer `gateway-service.properties` dans le dépôt. On gagne la centralisation et le rechargement à chaud de la configuration de la passerelle. L'annuaire pourrait techniquement être client (adresse fixe), mais cela crée une dépendance circulaire de démarrage (le serveur de configuration s'inscrit dans l'annuaire), donc ce n'est pas souhaitable.
9. **Retour arrière** : `git revert <commit>` dans le dépôt de configuration crée un nouveau commit qui annule la modification ; côté microservices, un seul `POST /actuator/refresh` par instance, sans redémarrage.
10. **Mode `native`** : on perd l'historique, l'auteur et la date des changements et le retour arrière par `git revert` ; il suffit pour un poste de développement ou un test local sans besoin de traçabilité.
11. **Sans IntelliJ** : à la racine `calculatrice-spring-cloud`, `mvn clean package -DskipTests` construit les cinq modules ; puis, dans cet ordre, `java -jar eureka-service/target/eureka-service-0.0.1-SNAPSHOT.jar`, `java -jar config-service/target/config-service-0.0.1-SNAPSHOT.jar`, `java -jar calcul-service/target/calcul-service-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev` (8081), `java -jar calcul-service/target/calcul-service-0.0.1-SNAPSHOT.jar --server.port=8083 --spring.profiles.active=prod`, `java -jar historique-service/target/historique-service-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev`, `java -jar gateway-service/target/gateway-service-0.0.1-SNAPSHOT.jar`.

## 4. Tests et captures

Les tableaux de tests des étapes C.5, D.4, D.5, D.6, E.1, E.3, F.1, F.2 et F.3 doivent être accompagnés des captures d'écran de Swagger UI ou du navigateur (requête, statut, corps), ainsi que des captures demandées (tableau de bord Eureka avec quatre services dont deux instances de `CALCUL-SERVICE`, `POST /actuator/refresh` et `GET /calcul/config` avant/après, deux réponses consécutives de la passerelle en profils dev et prod, six consoles).

*Section à compléter avec les captures réalisées lors de l'exécution.*

## 5. Journal Git du dépôt de configuration

Sortie de `git log --oneline` du dépôt `calculatrice-config-repo` (au moins trois commits : B.2, E.1, E.3) :

```
(à recopier après les étapes B.2, E.1 et E.3)
```
