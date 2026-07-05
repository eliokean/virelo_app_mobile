# Schéma des Couches de Sécurité (Sécurité en Profondeur)

Ce schéma représente le principe de **Défense en Profondeur** (Security-in-Depth) mis en place dans l'architecture Dual Offline de Virelo. Il montre comment un attaquant doit traverser plusieurs "barrières" pour espérer compromettre une transaction.

```mermaid
flowchart TD
    %% Définition des styles
    classDef couche1 fill:#1E88E5,stroke:#0D47A1,stroke-width:2px,color:#fff
    classDef couche2 fill:#00ACC1,stroke:#006064,stroke-width:2px,color:#fff
    classDef couche3 fill:#FDD835,stroke:#F57F17,stroke-width:2px,color:#333
    classDef couche4 fill:#43A047,stroke:#1B5E20,stroke-width:2px,color:#fff
    classDef hacker fill:#E53935,stroke:#B71C1C,stroke-width:3px,color:#fff,stroke-dasharray: 5 5

    Attaquant(("Hacker / Fraudeur")):::hacker

    subgraph Couche1 ["🛡️ Couche 1 : Sécurité Système & Environnement (Device)"]
        direction TB
        A1("No Cloud Backup<br/>(Bloque la restauration de sauvegarde)")
        A2("Flutter Secure Storage<br/>(Protège la Clé AES via Keystore/Keychain)")
        A3("Authentification Locale<br/>(PIN / Biométrie)")
    end
    
    subgraph Couche2 ["🗄️ Couche 2 : Sécurité des Données au Repos (Data at Rest)"]
        direction TB
        B1("Base de Données Hive Chiffrée<br/>(Chiffrement intégral AES-256)")
        B2("Déduction Optimiste<br/>(Bloque l'UI en cas de solde insuffisant)")
    end

    subgraph Couche3 ["🔐 Couche 3 : Sécurité Cryptographique (En transit hors-ligne)"]
        direction TB
        C1("Signature Numérique Ed25519<br/>(Garantit l'intégrité du Montant)")
        C2("Injection de l'UUID<br/>(Identifiant Unique)")
        C3("Timestamp (Horodatage)<br/>(Date d'expiration)")
    end

    subgraph Couche4 ["🏦 Couche 4 : Sécurité Serveur & Source de Vérité (Backend)"]
        direction TB
        D1("Vérification Libsodium<br/>(Validation mathématique de la signature Ed25519)")
        D2("Mécanisme Anti-Replay<br/>(Rejet si UUID déjà existant en base)")
        D3("Transactions ACID (Base de Données)<br/>(Aucune perte ou duplication de fonds)")
    end

    %% Chemin d'attaque
    Attaquant -->|Tente de manipuler l'appareil| Couche1
    Couche1 -->|Si appareil compromis| Couche2
    Couche2 -->|Si données extraites| Couche3
    Couche3 -->|Si payload altéré| Couche4
    
    %% Style des boîtes
    Couche1:::couche1
    Couche2:::couche2
    Couche3:::couche3
    Couche4:::couche4
```

### Explication des Couches (Pour la présentation orale) :

1. **Couche 1 (Environnement)** : Empêche les attaques passives. L'attaquant ne peut pas utiliser iCloud/Google Drive pour tricher, et ne peut pas accéder aux clés maîtresses sans contourner la puce de sécurité physique du téléphone (Keystore).
2. **Couche 2 (Données au repos)** : Même si le téléphone est "Rooté" ou "Jailbreaké" et que l'attaquant accède aux fichiers internes de l'application, la base de données contenant le solde et les reçus est un bloc indéchiffrable (AES-256).
3. **Couche 3 (Cryptographie)** : Si l'attaquant arrive par miracle à lire la base et tente de modifier un QR Code avant de le montrer au marchand, la signature Ed25519 (Elliptic Curve) protégera le montant. Il est impossible de recréer une signature sans la clé privée.
4. **Couche 4 (Le Mur Final)** : C'est le serveur. Même si l'attaquant possède un QR code 100% valide et parfaitement signé, s'il essaie de le faire scanner une deuxième fois, le serveur reconnaîtra l'UUID et bloquera la transaction (Anti-Rejeu).

*L'objectif de cette architecture est clair : si une couche vient à céder, la suivante prend le relais.*
