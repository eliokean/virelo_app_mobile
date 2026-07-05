# Architecture de Sécurité du Système Dual Offline (Virelo)

Ce document décrit les trois niveaux de sécurité (couches de défense) mis en place dans l'architecture Dual Offline de Virelo afin de garantir l'intégrité des transactions, la prévention de la double dépense et la réconciliation des données, même en l'absence totale de connectivité réseau.

## 1. Sécurité Locale (Prévention de la double dépense côté Client)
*Ce niveau empêche le client de tricher avec son propre appareil lorsqu'il est hors réseau.*

- **Déduction optimiste isolée** : Dès qu'un client génère un QR Code de paiement, le montant est immédiatement soustrait de son solde local stocké dans la mémoire chiffrée du téléphone (`FlutterSecureStorage` lié au Keystore/Keychain natif). Par exemple, avec un budget de 5 000 FCFA, après un paiement de 3 000 FCFA, l'application bloque toute génération de QR code supérieure à 2 000 FCFA.
- **Auto-destruction (Time-To-Live)** : La page affichant la preuve de paiement (`ShowOfflineProofPage`) intègre un Timer strict de 40 secondes. Passé ce délai, l'écran se ferme. Cela empêche les attaques par rejeu (*Replay Attacks*), comme la photographie d'un QR code pour un scan ultérieur.
- **Protection par PIN Local** : Il est impossible d'accéder au portefeuille hors ligne ou de générer une transaction sans avoir préalablement validé le code PIN local ou l'authentification biométrique.

## 2. Sécurité Cryptographique (Intégrité de la Preuve)
*Ce niveau garantit que le reçu échangé physiquement entre le client et le marchand ne peut pas être falsifié.*

- **Signature du Payload** : Le QR code n'est pas une simple chaîne de caractères. Il s'agit d'un objet JSON encodé en Base64 comprenant :
  - L'ID du client
  - Le montant exact de la transaction
  - Un Timestamp (horodatage)
  - Un **Token cryptographique de validation** généré lors de l'allocation initiale.
- **Inviolabilité** : Si un attaquant tente de modifier le code source de l'application cliente pour générer un faux payload (ex: modifier le montant), la signature cryptographique sera invalidée lors de la vérification par le serveur ou par la clé publique du marchand.

## 3. Sécurité Serveur / Base de Données (La Source de Vérité)
*C'est le filet de sécurité absolu. Même si un attaquant parvenait à contourner les protections locales de l'appareil, le backend rejette toute anomalie.*

- **Vérification du Solde Réel (`offline_balance`)** : Lors de la synchronisation par le marchand (`POST /api/offline/sync`), le backend Laravel ignore le solde théorique affiché sur le téléphone du client. Il interroge directement la base de données : `if ($clientWallet->offline_balance < $amount)`. Si le client n'a pas les fonds réels, la transaction est instantanément rejetée (`400 Bad Request`).
- **Atomicité des Transactions (ACID)** : Le transfert de fonds (débiter le compte hors ligne du client et créditer le solde principal du marchand) est enveloppé dans un bloc `DB::transaction()`. Si le serveur subit une défaillance au milieu du processus, la transaction est intégralement annulée (*rollback*). Il est informatiquement impossible que de l'argent soit dupliqué ou perdu.
- **Réconciliation automatique (Auto-réparation)** : Dès que l'application cliente retrouve un accès internet (lancement ou *Pull-to-Refresh*), elle interroge silencieusement le serveur pour écraser son cache local avec la véritable valeur du serveur, écrasant ainsi toute tentative de triche ou de modification du stockage local.

---
*Document généré pour la soutenance PFE - Implémentation Virelo*
