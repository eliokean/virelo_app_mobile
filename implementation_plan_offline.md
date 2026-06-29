# Mode Hors-Ligne (Télécollecte) pour le Marchand

Ce plan décrit comment nous allons implémenter la fonctionnalité "Offline" pour l'application Marchand, permettant d'accepter des paiements par QR Code même sans connexion internet, puis de les synchroniser plus tard (Télécollecte).

## Modifications proposées

### 1. Ajout de dépendances (Application Marchand)
- Ajouter `shared_preferences` pour le stockage local des transactions en attente.
- Ajouter `connectivity_plus` pour détecter si l'appareil a accès à internet.
- Ajouter `uuid` pour générer des identifiants uniques de transaction hors ligne.

### 2. Création du `OfflineSyncService`
Création d'un service dans l'application marchand pour :
- **Sauvegarder** une transaction scannée localement (Jeton + Montant + Timestamp + UUID).
- **Lire** les transactions en attente.
- **Synchroniser** (Télécollecte) : Envoyer le lot de transactions à l'API `/api/sync/telecollecte` et vider le stockage local en cas de succès.

### 3. Adaptation de l'écran d'encaissement (`receive_payment_page.dart`)
- Lors d'un scan, vérifier la connectivité.
- **Si en ligne** : Effectuer la transaction immédiatement via l'API `process-offline`.
- **Si hors-ligne** (ou erreur de réseau) : Enregistrer le jeton localement via `OfflineSyncService` et afficher un succès "Hors-ligne".

### 4. Adaptation du tableau de bord (`merchant_dashboard_page.dart`)
- Afficher un bandeau ou un bouton "Synchroniser (X en attente)" s'il y a des transactions locales.
- Au clic, lancer la méthode de synchronisation et rafraîchir les statistiques.

### 5. Ajustement du Backend (`SyncController.php`)
- Modifier `SyncController::telecollecte` pour utiliser automatiquement le premier terminal (`Terminal`) associé au marchand connecté, évitant ainsi à l'application mobile de devoir stocker et envoyer un `terminal_identifier` spécifique pour ce prototype.

## User Review Required
> [!IMPORTANT]
> Êtes-vous d'accord pour que les transactions hors-ligne soient stockées sur l'appareil du marchand via `shared_preferences` pour ce prototype ? (En production, nous utiliserions une base de données chiffrée comme Hive ou SQLCipher).

## Verification Plan
1. Couper le réseau (ou simuler) sur l'application Marchand.
2. Scanner un QR Code généré par le Client.
3. Vérifier que le paiement est accepté et stocké localement.
4. Rétablir le réseau.
5. Cliquer sur "Synchroniser" dans le tableau de bord.
6. Vérifier que la base de données Backend reçoit bien la transaction.
