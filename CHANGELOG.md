# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [Unreleased] - 2026-07-04

### Ajouté
- **virelo_core** : Dépendance `cryptography` ajoutée pour la gestion des paires de clés asymétriques.
- **virelo_core** : Implémentation du modèle `OfflineAuthorizationPayload` pour le paiement asynchrone hors ligne.
- **virelo_core** : Création du service `OfflineStorageService` permettant de stocker de façon sécurisée (KeyStore/KeyChain) la paire de clés Ed25519 et de gérer l'incrémentation du `nonce` (Sequence Number).
- **virelo_core** : Création du service `OfflineCryptoService` pour la génération et la signature de la promesse de débit hors ligne.
- **virelo_client** : Mise à jour de `ScanContactPage` pour intercepter les requêtes NFC/QR de paiement hors ligne (`virelo://offline_pay`), générer le payload signé cryptographiquement, et afficher un indicateur de chargement.

### Modifié
- **virelo_core** : Ajout du champ `clientPublicKey` au modèle `OfflineAuthorizationPayload` pour permettre la vérification 100% hors ligne par le marchand.
- **virelo_client** : Mise à niveau de `ScanContactPage` pour un usage en production (abandon du PoC) :
  - Lecture des véritables données NDEF sur les puces NFC au lieu de simuler un scan.
  - Vérification stricte de l'authentification (jeton d'erreur si l'utilisateur est déconnecté).
  - Après la génération du payload hors ligne, redirection vers `ShowOfflineProofPage` pour affichage du QR Code signé au marchand.
- **virelo_client** : Mise à niveau de `ReceiveOfflinePage` (Marchand) :
  - Suppression de la vérification factice.
  - Utilisation de `OfflineCryptoService.verifyPayload()` pour valider rigoureusement la signature cryptographique du reçu hors ligne avant acceptation.
