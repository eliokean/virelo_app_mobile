# Roadmap Frontend — Virelo
### 2 apps Flutter (Client + Marchand) — Clean Architecture, Offline-First, code partagé

---

## 🎯 Vue d'ensemble

Le cahier des charges prévoit **2 apps distinctes** : l'app **Client** (déjà entièrement détaillée dans `VIRELO_FLUTTER_GUIDE_COMPLET.md` et `VIRELO_DESIGN_SYSTEM.md`) et l'app **Marchand** (encaissement, pas encore détaillée). Plutôt que de dupliquer toute la logique technique critique (chiffrement, synchronisation offline, client API) dans deux projets séparés, cette roadmap propose une architecture en **monorepo avec packages partagés**, et priorise les features des deux apps ensemble vu l'échéance du stage (30 juin).

**Stack frontend (rappel) :** Flutter/Dart · BLoC · GetIt (DI) · GoRouter · Dio · SQLite (stockage offline) · `flutter_secure_storage` · `local_auth` (biométrie) · `firebase_messaging` (push) · `smile_id` (KYC) · `qr_flutter`

---

## 🏗️ Architecture — 2 apps + code partagé (monorepo)

**Clean Architecture** à 3 couches par feature dans chaque app (dépendance toujours de l'extérieur vers l'intérieur : Presentation → Domain → Data), comme déjà actée dans le guide. La nouveauté ici : isoler dans des **packages partagés** tout ce qui n'est pas spécifique à une app, pour ne pas coder deux fois la même logique critique.

### Arborescence

```
virelo/
├── apps/
│   ├── virelo_client/                  # App Client — détaillée dans VIRELO_FLUTTER_GUIDE_COMPLET.md
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   ├── config/                 # DI, routes, env (spécifiques à cette app)
│   │   │   └── features/
│   │   │       ├── auth/ wallet/ transfer/ deposit/ kyc/
│   │   │       └── card/ share/ billing/ conversion/ history/ notifications/ profile/ onboarding/
│   │   ├── android/                    # permissions NFC/HCE/caméra, apduservice.xml
│   │   └── pubspec.yaml                # dépend de virelo_core + virelo_design_system
│   │
│   └── virelo_marchand/                # App Marchand — nouvelle, structure miroir mais plus simple
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   ├── config/
│       │   └── features/
│       │       ├── auth/                 # login marchand lié au Terminal, pas de biométrie client
│       │       ├── encaissement/          # saisie montant + scan NFC/QR + lecture carte MIFARE + PIN
│       │       ├── historique/             # transactions encaissées, statut sync
│       │       └── terminal/                # statut d'activation du terminal (lecture seule)
│       ├── android/                    # mode lecteur NFC (pas HCE — le marchand lit, ne simule pas une carte)
│       └── pubspec.yaml                # dépend des mêmes packages partagés
│
├── packages/
│   ├── virelo_core/                    # Logique technique partagée — PAS d'UI ici
│   │   └── lib/
│   │       ├── network/                # ApiClient, AuthInterceptor (Dio)
│   │       ├── crypto/                 # CryptoUtils (AES-256), identique aux deux apps
│   │       ├── offline_sync/            # SyncService, modèle Transaction, déduplication par UUID
│   │       ├── connectivity/            # ConnectivityService
│   │       └── storage/                 # Wrapper SQLite + flutter_secure_storage
│   │
│   └── virelo_design_system/           # Composants UI partagés — détaillé dans VIRELO_DESIGN_SYSTEM.md
│       └── lib/
│           ├── theme/                  # AppColors, AppTextStyles, AppSpacing, AppShadows
│           └── widgets/                 # VireloPrimaryButton, BalanceCard, OfflineBanner...
│
├── melos.yaml                          # Orchestration du monorepo
└── pubspec.yaml
```

**Pourquoi un package partagé plutôt que deux projets isolés :**
- `virelo_core` contient le moteur de synchronisation offline et le chiffrement AES-256, **identiques** côté Client (qui paie) et côté Marchand (qui encaisse) — seule la donnée transportée diffère. Le coder une fois évite que les deux apps divergent sur la logique de déduplication par UUID
- Un bug corrigé dans `SyncService` se corrige une seule fois pour les deux apps
- `virelo_design_system` garde une cohérence visuelle entre les deux apps si vous le souhaitez (l'app Marchand peut aussi avoir son propre thème plus sobre/utilitaire — à trancher selon le temps disponible)

**Différence clé Client ↔ Marchand côté NFC :** le Client utilise le **HCE** (Host Card Emulation — le téléphone *simule* une carte). Le Marchand utilise le téléphone en **mode lecteur NFC classique** (il *lit* la carte/jeton du client ou le badge MIFARE physique) — ce sont deux APIs Android différentes, pas juste une question de rôle dans l'UI.

> **Si le temps presse (9 jours avant la fin du stage) :** un vrai monorepo `melos` ajoute un coût d'outillage. Alternative pragmatique : pas de monorepo, deux projets Flutter indépendants, et vous dupliquez à la main les 3-4 fichiers vraiment critiques (`crypto_utils.dart`, `sync_service.dart`, `api_client.dart`) en les gardant identiques. Moins propre pour la soutenance sur le plan architectural, mais zéro risque de blocage d'outillage à ce stade.

---

## 🗺️ Phasage par feature

| Priorité | App | Feature | RG associée | Pourquoi prioritaire (ou pas) |
|---|---|---|---|---|
| 🔴 P0 | Partagé | `virelo_core` (réseau, crypto, sync) | — | Les deux apps en dépendent, à stabiliser avant tout le reste |
| 🔴 P0 | Client | Auth | RG1 | Sans authentification biométrique, aucun écran n'est accessible |
| 🔴 P0 | Client | Wallet | RG3 | Le solde embarqué est au cœur de toute la démo |
| 🔴 P0 | Client | Transfer (NFC + QR) | RG2, RG5 | C'est la fonctionnalité qui justifie tout le projet |
| 🔴 P0 | Client | Offline & Télécollecte | RG2, RG4 | Sans ça, "offline" n'est qu'un mot dans le titre du mémoire |
| 🔴 P0 | Marchand | Auth/Terminal | — | Sans ça, aucun encaissement ne peut être attribué à un marchand |
| 🔴 P0 | Marchand | Encaissement (lecture NFC/QR/carte) | RG2, RG5 | C'est le miroir exact de Transfer côté Client — sans lui, aucune démo bout-en-bout possible |
| 🔴 P0 | Marchand | Offline & sync | RG2, RG4 | Réutilise `virelo_core` — doit fonctionner main dans la main avec Transfer côté Client |
| 🟠 P1 | Client | Deposit (recharge Mobile Money) | RG6 | Nécessaire pour avoir un solde à dépenser en démo |
| 🟠 P1 | Client | Onboarding | — | Première impression en soutenance, mais peut rester simple |
| 🟠 P1 | Client | History | — | Utile pour montrer la cohérence des transactions synchronisées |
| 🟠 P1 | Marchand | Historique des encaissements | — | Symétrique à History côté Client, même valeur de démonstration |
| 🟡 P2 | Client | Notifications (FCM) | — | Valeur ajoutée, mais la démo fonctionne sans |
| 🟡 P2 | Client | Profile | — | Écran secondaire, faible risque si simplifié |
| 🟡 P2 | Marchand | Statut Terminal (lecture) | — | Confort de diagnostic, pas critique pour la démo |
| 🟢 P3 | Client | KYC (Smile ID) | — | Différenciateur produit, hors du cœur "paiement offline NFC" du mémoire |
| 🟢 P3 | Client | Card (cartes virtuelles) | — | Fonctionnalité d'extension, pas dans le cahier des charges initial |
| 🟢 P3 | Client | Share, Billing, Conversion | — | Confort produit, à ne traiter qu'une fois P0/P1 solides |

---

## Phase 1 — Cœur fonctionnel (P0)

### `virelo_core` (package partagé) — à faire en premier
- `CryptoUtils` (AES-256), `SyncService` (déduplication par UUID, ordonnancement par horodatage local), `ApiClient` (Dio + intercepteur d'auth), `ConnectivityService`
- Les deux apps consomment ce package — toute correction de bug ici profite immédiatement aux deux
- → base directement transposable depuis les sections 4 et 9 du guide (déjà écrites pour le Client, à généraliser pour être app-agnostique)

### Auth (RG1) — Client
- Use cases : `LoginUseCase`, `SendOtpUseCase`, `VerifyOtpUseCase`
- Point d'attention : la biométrie (`local_auth`) ne fait que déverrouiller un token déjà stocké en `flutter_secure_storage` — le serveur ne reçoit jamais de donnée biométrique brute (cohérent avec la Phase 1 du backend)
- → détail complet : section 6 du guide

### Wallet (RG3) — Client
- `BalanceCard` doit afficher en permanence le **solde local**, distinct du solde serveur recalculé après sync
- Le solde local se décrémente immédiatement au paiement (perception de vitesse), mais reste un état "optimiste" tant que la télécollecte n'a pas confirmé côté serveur
- → détail complet : section 7 du guide

### Transfer NFC + QR (RG2, RG5) — Client
- HCE côté app (émulation carte) pour le paiement par contact, fallback QR si pas de NFC
- `initiate_nfc_payment_usecase` / `initiate_qr_payment_usecase` / `receive_payment_usecase`
- Permissions Android critiques à valider tôt : NFC, HCE, caméra (voir section 1.2 du guide — `apduservice.xml`)
- → détail complet : section 8 du guide, flows détaillés section 11 du design system

### Offline & Télécollecte (RG2, RG4) — Client
- Stockage local chiffré AES-256 des transactions en attente (SQLite), via `virelo_core`
- `SyncService` détecte le retour réseau et envoie le batch vers l'API Laravel (qui les traite via la queue Redis côté backend — cohérence directe avec la Phase 5 du backend)
- Badge offline visible en permanence sur les écrans principaux (jamais d'erreur fatale si pas de réseau — c'est un principe du design system, pas une option)
- → détail complet : section 9 du guide

### Auth/Terminal — Marchand (nouveau)
- Login simple (identifiant + mot de passe ou PIN marchand), lié côté backend à un `Terminal` autorisé (Phase 2 du backend) — pas de biométrie client ici, le marchand n'est pas le payeur
- Au démarrage, vérifier l'état d'activation du `Terminal` ; si désactivé, bloquer l'accès à l'écran d'encaissement même hors-ligne (le check côté serveur reste l'arbitre final à la télécollecte, mais un blocage local immédiat évite déjà une mauvaise expérience)

### Encaissement — Marchand (nouveau, miroir de Transfer côté Client)
- Saisie du montant à encaisser, puis 3 modes de réception : scan NFC (lecture, pas HCE), scan QR Code affiché par le client, lecture d'une carte/badge MIFARE physique suivie de la saisie du PIN client
- Génère localement une transaction avec UUID, stockée via `virelo_core` exactement comme côté Client — c'est la symétrie qui rend la télécollecte cohérente des deux côtés

### Offline & sync — Marchand (nouveau)
- Réutilise directement `SyncService` de `virelo_core` — aucune raison de redévelopper cette logique
- Le batch envoyé à `POST /sync/batch` contient les transactions encaissées par ce terminal précis

**Point de vigilance transverse P0 :** Transfer (Client) et Encaissement (Marchand) doivent être développés en miroir, idéalement testés ensemble dès que possible — un paiement NFC ne se valide qu'à la rencontre des deux. Ne pas finaliser l'un sans avoir testé un aller-retour réel avec l'autre, même en mode dégradé.

---

## Phase 2 — Compléter le parcours (P1)

### Deposit / recharge Mobile Money (RG6)
- Grille des opérateurs (Wave, Orange, MTN, Moov) → appelle l'API backend qui relaie vers l'orchestrateur GeniusPay
- Le crédit du wallet n'est confirmé qu'après le webhook backend, pas au moment du clic — l'UI doit refléter un état "en cours" plutôt que de créditer le solde local immédiatement (contrairement au paiement NFC/QR, ici on attend la confirmation serveur car c'est une entrée d'argent, pas une sortie)
- → détail complet : section 11 du guide

### Onboarding & History — Client
- Onboarding : peut rester minimaliste (3 écrans max) sans nuire à la démo
- History : liste des transactions avec statut visuel clair (synchronisée / en attente / rejetée) — directement utile pour montrer en soutenance que la télécollecte fonctionne réellement

### Historique & statut Terminal — Marchand
- Historique des encaissements : même logique d'affichage par statut que côté Client, peut réutiliser des composants de `virelo_design_system` si vous gardez un thème cohérent entre les deux apps
- Statut Terminal : écran de lecture simple (actif/désactivé, dernière synchronisation réussie) — utile en démo pour montrer concrètement qu'un terminal désactivé ne peut plus encaisser

---

## Phase 3 — Finitions & confort (P2/P3)

- **Notifications (FCM)** : reçus de paiement, rappel de synchronisation
- **Profile** : infos compte, paramètres
- **KYC (Smile ID), Card, Share, Billing, Conversion** : à ne démarrer que si P0/P1 sont stables et qu'il reste du temps — ce sont des différenciateurs produit, pas des éléments évalués par le cahier des charges académique initial

---

## 🧪 Transverse — Tests, build, soutenance

- Tests unitaires prioritaires : `CryptoUtils` (chiffrement local) et `SyncService` (déduplication/sync) — déjà fournis avec exemples complets dans le guide (section 21)
- Checklist avant soutenance (section 23 du guide) à traiter comme une todo-list finale : test NFC physique marchand↔client, test coupure réseau réelle, test biométrie valide/invalide
- Build release : signature Android (`key.properties`, ne jamais committer), `flutter build appbundle --release`

---

## 📌 Points d'attention transverses

- **Le solde local n'est qu'une estimation optimiste** : la vérité reste toujours côté serveur (cohérent avec la règle équivalente du backend)
- **Aucune donnée biométrique brute ne quitte le téléphone**
- **Design tokens uniquement** : pas de couleur ou style en dur dans les widgets, tout passe par `AppColors`/`AppTextStyles`/`AppSpacing`/`AppShadows`
- **Le badge offline doit toujours être visible** quand le réseau est absent — jamais d'écran bloqué ou d'erreur fatale
- **Toute modification de `virelo_core` impacte les deux apps** : testez Client ET Marchand après chaque changement dans le package partagé, pas seulement l'app sur laquelle vous travailliez au moment du changement
- **HCE (Client) ≠ lecteur NFC (Marchand)** : ce sont deux implémentations Android différentes, ne pas supposer qu'un code NFC qui marche côté Client se réutilise tel quel côté Marchand

---

## Prochaines étapes possibles

Je peux, sur demande :
- Détailler le plan de tests d'intégration NFC physique (marchand ↔ client) pour la soutenance
- Croiser précisément chaque écran avec l'endpoint backend qu'il consomme (table de correspondance Frontend ↔ Backend)
- Revoir la priorisation P0-P3 si votre état d'avancement réel diffère de ce qui est supposé ici
