# Architecture du Système : Paiement Dual-Offline par Promesse de Débit Asynchrone Sécurisée (Modèle "Chèque Numérique")

## 1. Introduction et Philosophie du Système
Pour résoudre le problème de la double dépense en mode offline-first **sans imposer à l'utilisateur le blocage de fonds** dans un coffre-fort virtuel (wallet de secours), ce système adopte une approche de traitement différé (asynchrone) inspirée du modèle bancaire des billets à ordre et des autorisations hors ligne des cartes de crédit.

Plutôt que de chercher à modifier un solde en temps réel sans réseau, l’application cliente génère une **promesse de débit irrévocable et cryptographiquement signée**. La sécurité du système ne repose pas sur l'affichage du téléphone du client, mais sur une défense en trois couches associant isolation matérielle, traçabilité algorithmique et gestion des risques.

## 2. L'Architecture en 3 Couches Sécurisées

```text
┌──────────────────────────────────────────────────────────────┐
│ COUCHE 1 : ISOLATION MATÉRIELLE (KeyStore / KeyChain)        │ -> Immunise la clé contre le vidage de cache
├──────────────────────────────────────────────────────────────┤
│ COUCHE 2 : TRAÇABILITÉ ALGORIHTMIQUE (Nonce Séquentiel)      │ -> Identifie mathématiquement la double dépense
├──────────────────────────────────────────────────────────────┤
│ COUCHE 3 : GESTION DU RISQUE ÉCONOMIQUE (Plafond & Assurance)│ -> Protège le commerçant et pénalise le fraudeur
└──────────────────────────────────────────────────────────────┘
```

### Couche 1 : L'Isolation Matérielle (Résistance au vidage de cache)
Pour empêcher un utilisateur malveillant de modifier son application pour tricher, la clé privée du client est générée et stockée dans l'**Android KeyStore** ou l'**iOS KeyChain** (via le plugin `flutter_secure_storage`).
Ces espaces système sont isolés physiquement du stockage applicatif. Si l'utilisateur clique sur "Vider le cache" ou force l'arrêt de l'application, les clés cryptographiques restent intactes. Si l'application est désinstallée/réinstallée hors ligne, le système refuse de signer toute transaction tant qu'une reconnexion au serveur n'a pas validé un nouveau certificat, bloquant ainsi la fraude à la source.

### Couche 2 : La Traçabilité Algorithmique (Détection de la double dépense)
Le système maintient un compteur de séquence local (Nonce) strict au sein du stockage sécurisé. Chaque transaction hors ligne génère un bloc de données (Payload) contenant :
- L'identifiant unique du client (`clientId`)
- Le montant de la transaction (`amount`)
- L'identifiant du commerçant (`merchantId`) pour éviter les attaques par rejeu
- Le numéro de séquence actuel du compteur (`sequenceNumber`)

Ce bloc est entièrement **signé par la clé privée du client**. Dès qu'un paiement est effectué, le compteur passe à +1.
Si le fraudeur tente de réinitialiser son téléphone pour réutiliser la transaction #1 chez un autre commerçant, le serveur central détectera immédiatement la collision (deux transactions différentes portant le même numéro de séquence pour un même utilisateur) lors de la phase de réconciliation.

### Couche 3 : La Gestion du Risque Économique (Théorie des jeux)
Puisque le traitement final est asynchrone, un utilisateur malveillant pourrait disparaître après avoir créé une fausse dette. Le système intègre deux règles économiques pour y faire face :
1. **Le Plafond Hors Ligne (Floor Limit)** : L'application du marchand intègre une règle stricte interdisant les paiements hors ligne au-dessus d'un montant faible (ex: 15 €) et limite le nombre de transactions successives.
2. **Le Contrat et Solde Négatif** : À la reconnexion, si le compte courant du client n'a pas les fonds, le serveur central bascule le compte en solde négatif et gèle l'identité numérique de l'utilisateur (liée à un protocole KYC d'ouverture de compte). Le commerçant est quant à lui immédiatement remboursé par un fonds de garantie alimenté par les micro-commissions du système.

---

## 3. Cycle de Vie d'une Transaction (Pas à Pas)

### Étape A : La Transaction Hors Ligne (Client <-> Marchand)
1. Le Marchand saisit le montant sur son application Flutter et génère un défi (décompté via un QR Code ou un signal NFC).
2. L'application Flutter du Client scanne le code, récupère les données, incrémente son compteur de séquence interne et signe le tout cryptographiquement.
3. Le Marchand reçoit la signature, vérifie localement la validité mathématique grâce à la clé publique du client, valide visuellement le paiement et enregistre le reçu dans sa base de données chiffrée locale (SQLite / Isar).

### Étape B : La Réconciliation Asynchrone (Marchand -> Serveur)
1. Dès que le Marchand retrouve une connexion internet, il clique sur "Synchroniser" pour envoyer son lot de reçus signés au serveur central.
2. Le serveur central (Node.js/Python/PHP ou Smart Contract) traite les signatures, vérifie l'ordre des numéros de séquence, débite le compte courant des clients et crédite le compte du marchand.
3. Si une anomalie de séquence ou une provision insuffisante est détectée, le mécanisme de gestion des risques s'active (indemnisation du marchand et gel du compte client).

---

## 4. Modèle de Données du Ticket (Code Dart Flutter)

Voici la structure exacte du paquet de données échangé hors ligne :

```dart
class OfflineAuthorizationPayload {
  final String clientId;        // Identifiant unique du payeur
  final String merchantId;      // Identifiant unique du bénéficiaire
  final double amount;          // Montant de la transaction
  final int sequenceNumber;     // Compteur strict anti-réinitialisation
  final String timestamp;       // Date et heure de l'échange
  final String clientSignature; // Signature de l'ensemble des champs par le KeyStore

  OfflineAuthorizationPayload({
    required this.clientId,
    required this.merchantId,
    required this.amount,
    required this.sequenceNumber,
    required this.timestamp,
    required this.clientSignature,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'merchantId': merchantId,
        'amount': amount,
        'sequenceNumber': sequenceNumber,
        'timestamp': timestamp,
        'clientSignature': clientSignature,
      };
}
```
