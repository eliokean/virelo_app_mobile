# Schéma de l'Architecture de Sécurité Dual Offline

Voici le diagramme d'architecture qui modélise l'ensemble des systèmes de sécurité mis en place pour Virelo. Tu pourras directement inclure ce diagramme dans ton mémoire de PFE !

```mermaid
sequenceDiagram
    participant OS as OS (Android/iOS)
    participant Client as Application Client (Flutter)
    participant QR as QR Code / NFC
    participant Merchant as App Marchand (Flutter)
    participant Server as Backend (Laravel / PHP)
    participant DB as Base de Données

    Note over OS, Client: 1. Sécurité de Stockage (Approche Hybride)
    OS->>Client: Demande d'Ouverture de l'App
    Client->>OS: Lecture Keystore (Flutter Secure Storage)
    OS-->>Client: Retourne la Clé AES-256
    Client->>Client: Déverrouillage de Hive (Base Locale Chiffrée)
    Note over OS: Bloquage Backup Cloud (AndroidManifest)

    Note over Client, QR: 2. Génération de Preuve & Anti-Rejeu
    Client->>Client: Récupération de la clé privée (Ed25519)
    Client->>Client: Génération d'un UUID unique (Nonce)
    Client->>Client: Construction du Payload (Montant + UUID + Temps)
    Client->>Client: Signature du Payload avec la clé privée Ed25519
    Client->>QR: Affichage du QR Code (Payload Clair + Signature Numérique)

    Note over QR, Server: 3. Transmission et Validation
    Merchant->>QR: Scan du QR Code Hors Ligne
    Merchant->>Server: /api/offline/sync (Dès retour Internet)
    
    Note over Server, DB: 4. Vérifications Backend Intransigeantes
    Server->>Server: Reconstitution du $dataToSign
    Server->>Server: Libsodium: Vérifie Signature Ed25519 avec Clé Publique
    alt Signature Invalide / Falsifiée
        Server-->>Merchant: ❌ 400 Bad Request (Rejet immédiat)
    else Signature Valide
        Server->>DB: Recherche UUID dans table `transfers`
        alt UUID Existant
            Server-->>Merchant: ❌ 400 Bad Request (Replay Attack Détectée)
        else UUID Inconnu
            Server->>DB: Démarrer DB::transaction()
            DB->>DB: Débit Solde Hors Ligne Client
            DB->>DB: Crédit Solde Marchand
            DB->>DB: Insertion UUID dans transfers (Verrouillage)
            DB-->>Server: Transaction Validée (ACID)
            Server-->>Merchant: ✅ 200 OK (Synchronisation réussie)
        end
    end
```

### Comment lire ce schéma ?

Ce diagramme séquentiel se décompose en 4 zones de sécurité :
1. **Sécurité de Stockage (Hybride)** : L'OS mobile fournit la clé matérielle qui déverrouille le coffre-fort local Hive, tout en interdisant le clonage vers le Cloud.
2. **Génération (Anti-Rejeu)** : L'application forge le reçu de transaction et lui attache une signature infalsifiable (Ed25519) ainsi qu'un "Numéro de série" unique (UUID).
3. **Transmission** : Le QR code transporte la promesse de débit sans qu'aucune connectivité réseau ne soit requise entre le client et le marchand.
4. **Le Juge (Backend)** : Le serveur Laravel ne fait confiance à personne. Il vérifie les mathématiques (Libsodium), vérifie ses registres (Anti-Rejeu), et applique un mouvement de fonds atomique.
