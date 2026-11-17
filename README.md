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

**E.3.** Expérience réalisée : `calcul.message` modifié dans `calcul-service.properties` **sans commit**. `GET http://localhost:9999/calcul-service/default` renvoie immédiatement la nouvelle valeur, alors que le champ `version` reste `09ba676…` (le dernier commit) : pour un dépôt local `file:///`, le serveur lit l'**arbre de travail** (les fichiers tels qu'ils sont sur le disque) et non les commits. Après `POST /actuator/refresh` sur 8081, `GET /calcul/config` affiche la nouvelle valeur (la réponse du refresh ne liste que `calcul.message`, sans `config.client.version`, puisque `version` n'a pas changé). Le commit n'est donc pas nécessaire au serveur dans ce mode, mais il fait changer `version` (donc apparaître `config.client.version` dans la réponse du refresh), laisse une trace (qui, quand, quoi) et permet `git revert`. Avec un dépôt distant (`https://…`), le serveur clone le dépôt puis le met à jour (`fetch`/`pull`) : il ne voit alors que ce qui a été commité **et poussé** ; une modification locale non poussée n'a aucun effet. Le comportement n'est donc pas le même.

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

Les tests ci-dessous ont été **réellement exécutés** sur le poste (consoles IntelliJ : Eureka 8761, config-service 9999, calcul-service 8081 et 8083, historique-service 8082, gateway 8888) ; les réponses sont recopiées telles quelles. Les captures d'écran demandées (Swagger UI ou navigateur, tableau de bord Eureka, six consoles dont la ligne `Located environment`) sont à joindre dans le dossier `Captures` ; les tests C.5 (huit requêtes) y figurent déjà.

### Résultats relevés


#### D.5 (historique 8082, profil default)

- `GET :8082/operations/config -> {"service":"historique-service","port":8082,"profil":"default","maxOperations":50,"message":"Configuration par defaut (profil default)","equipe":"Equipe Calculatrice - FSS"}`
- `POST /operations somme 8+2 -> 201 {"id":1,"operateur":"somme","a":8,"b":2,"resultat":10.0}`
- `POST /operations produit 5000*2 -> 400 {"erreur":"Erreur : operande hors limite (max 1000)"}`
- `POST /operations division 7/0 -> 400 {"erreur":"Erreur : division par 0 impossible"}`
- `GET /operations -> 200 [{"id":1,...somme...}]`

#### D.4 (8083 default) GET :8083/calcul/config -> {"service":"calcul-service","port":8083,"profil":"default","maxOperande":1000,"message":"Configuration par defaut (profil default)","equipe":"Equipe Calculatrice - FSS"}


#### D.6 gateway 8888

- `/calcul-service/calcul/config (x2, alternance) -> port 8083 puis port 8081 (profil default, maxOperande 1000)`
- `/historique-service/operations/config -> port 8082, maxOperations 50`
- `/config-service/calcul-service/default -> 200, version 09ba676cc5f6153bbef95860b5c76fb3ce393735, sources calcul-service.properties + application.properties`
- `/actuator/gateway/routes -> routes ReactiveCompositeDiscoveryClient_CALCUL-SERVICE (lb://CALCUL-SERVICE, RewritePath), GATEWAY-SERVICE, ...`

#### E.1/E.2

- `Modif calcul-service.properties 1000->2000 (fichier modifie, NON commite au moment du test)`
- `Serveur: /config-service/calcul-service/default -> calcul.max-operande=2000, version encore 09ba676 (file:// = lit l'arbre de travail)`
- `8081 AVANT refresh: maxOperande 1000`
- `8083 AVANT refresh: maxOperande 1000`
- `POST :8081/actuator/refresh -> 200 ["calcul.max-operande"]`
- `8081 APRES: maxOperande 2000 ; GET /calcul/produit?a=1500&b=1 -> 200 1500`

#### E.3 experience (modification non commitee de calcul.message)

- `GET :9999/calcul-service/default -> version 09ba676... INCHANGEE ; calcul-service.properties: calcul.max-operande=2000, calcul.message="Message modifie sans commit (experience E.3)" => le serveur lit l'ARBRE DE TRAVAIL du depot local file:///`
- `8081 avant refresh: message ancien ; POST /actuator/refresh -> 200 ["calcul.message"] (pas de config.client.version car version inchangee) ; apres: message nouveau`

#### E.3 (apres 3 commits: git log = bc13497 / aa372a0 / 09ba676)

- `POST :8082/actuator/refresh -> 200 ["config.client.version","historique.max-operations","historique.message","calculatrice.equipe"]`
- `GET /operations/config apres refresh -> maxOperations 2, message "Limite abaissee a 2 (modification E.3)", equipe "Equipe Calculatrice - FSS" (ANCIENNE: @Value sans @RefreshScope)`
- `(incident: calcul-service desinscrit d'Eureka -> 503 sur POST; services relances)`
- `Sequence rejouee (historique relance, vide): POST 8+2 -> 201 id1 ; POST 1+1 -> 201 id2 ; POST 2+2 -> 409 {"erreur":"Historique plein : 2 operations au maximum"} ; DELETE /operations/1 -> 204 ; POST 2+2 -> 201 id3 ; GET -> [id2,id3]`

#### Incident refresh/Eureka (corrige)

- `Apres POST /actuator/refresh, calcul-service disparait d'Eureka (console Eureka: "Cancelled instance", puis "lease doesn't exist" / Not Found (Renew); console client: HTTP 400 au register). Cause: le client Eureka est @RefreshScope, detruit (deregistre) par le refresh.`
- `Correctif: eureka.client.refresh.enable=false dans application.properties de calcul-service et historique-service. Apres correctif: refresh 200 [] et les 5 instances restent UP apres 20 s.`

#### F.1 / F.2 (8081 --spring.profiles.active=dev ; 8083 --server.port=8083 --spring.profiles.active=prod)

- `Gateway /calcul-service/calcul/config x6 -> alternance: {port 8081, profil dev, maxOperande 100, message "Profil dev : operandes limites a 100"} / {port 8083, profil prod, maxOperande 1000000, message "Profil prod : operandes limites a 1 000 000"}`
- `Gateway /calcul-service/calcul/somme?a=500&b=1 x6 -> alternance 400 "Erreur : operande hors limite (max 100)" / 200 501`

#### F.3 historique profil dev

- `GET :8082/operations/config -> {"service":"historique-service","port":8082,"profil":"dev","maxOperations":3,"message":"Profil dev : 3 operations au maximum","equipe":"Equipe Calculatrice - FSS (modification E.3)"}`
- `3 POST somme 1+1 -> ids 1,2,3 (GET /operations liste les 3) ; POST suivants -> 409 {"erreur":"Historique plein : 3 operations au maximum"}`
- `:9999/historique-service/dev -> version bc134979ec79..., historique-service-dev.properties max-operations=3 ; historique-service.properties =2 ; application.properties (aucune)`

### Incident rencontré et corrigé (refresh et Eureka)

Après un `POST /actuator/refresh`, `calcul-service` disparaissait de l'annuaire (console Eureka : `Cancelled instance`, puis `lease doesn't exist`; console du service : erreur 400 au réenregistrement), ce qui rendait la passerelle et OpenFeign inopérants (réponse 503 « calcul-service injoignable »). Cause : le client Eureka est un bean `@RefreshScope`, détruit (et désinscrit) par le refresh. Correctif : `eureka.client.refresh.enable=false` dans le `application.properties` local de `calcul-service` et d'`historique-service`. Vérifié : après le correctif, un refresh répond `200` et les cinq instances restent `UP`.

Remarque : lors de la séquence F.3, la sortie des trois premiers `POST` a été perdue à cause d'une erreur dans mon script de test ; leur effet est prouvé par le `GET /operations` qui liste les opérations 1, 2 et 3, et par les 409 qui suivent.

## 5. Journal Git du dépôt de configuration

Sortie de `git log --oneline` du dépôt `calculatrice-config-repo` (B.2, E.1, E.3) :

```
bc13497 Limite d'historique-service abaissee a 2, nom d'equipe modifie
aa372a0 Limite de calcul-service relevee a 2000
09ba676 Configuration initiale de la calculatrice
```
