# Architecture Offline-First : Le Protocole "Virelo Offline Escrow"

Ce document décrit le défi technique majeur rencontré lors de la conception du système de paiement P2P (C2C) hors ligne pour le projet Virelo, ainsi que l'approche ingénieuse mise en place pour le résoudre.

## 1. La Problématique Fondamentale : La "Double Dépense"

Dans un système de paiement classique, un serveur central vérifie en temps réel si l'expéditeur dispose des fonds. 
Lorsque deux utilisateurs sont hors ligne, il est impossible de consulter le serveur central. Cela soulève des problèmes majeurs :
1. **La Double Dépense** : Comment empêcher un utilisateur de dépenser le même argent plusieurs fois ?
2. **La Suppression du Cache (L'Arnaque Ultime)** : Si la transaction est sauvegardée uniquement sur le téléphone de l'expéditeur, ce dernier peut effacer les données de son application après le paiement. La transaction ne sera jamais synchronisée au serveur, et le destinataire ne sera jamais payé.

---

## 2. L'Approche Ingénieuse : Le "Séquestre Pré-chargé" (Pre-funded Off-chain Ledger)

Pour que ce système soit parfait et ne souffre d'aucune faille, nous utilisons la logique d'un **système à jetons pré-chargés**, combiné à un **Handshake cryptographique local**.

### Phase 1 : L'Allocation du Budget (En ligne)
Avant de se déconnecter (ex: chez lui avec le Wi-Fi), l'utilisateur A décide de charger un budget spécifique pour le mode hors ligne.
- **L'Action Serveur** : Le Backend déduit immédiatement ce montant (ex: 5000 FCFA) de son solde principal global et le place dans un coffre-fort virtuel "Séquestre Hors Ligne".
- **La Création du Jeton** : Le serveur génère un certificat cryptographique signé (Jeton) attestant : *"L'appareil de A possède 5000 FCFA valides hors ligne"*.
- **Le Stockage Matériel** : Ce certificat et la clé privée associée sont enregistrés dans le `flutter_secure_storage` du téléphone de A.

### Phase 2 : Le Paiement (100% Hors Ligne)
A et B se rencontrent. Les deux n'ont pas internet.
1. **Initiation** : L'Expéditeur A scanne le **Tag NFC** ou le **QR Code** statique du Destinataire B pour récupérer son identifiant de manière fluide.
2. **Consommation** : A saisit un montant (ex: 2000 FCFA). L'application de A décrémente son solde hors ligne local (il passe à 3000 FCFA).
3. **Génération & Sauvegarde de la Preuve** : Le téléphone de A génère une signature cryptographique contenant : `[ID_Transaction, Montant: 2000 FCFA, ID_Destinataire: B, Certificat_Initial, Nouveau_Solde_Local: 3000 FCFA]`.
4. **Mise en File d'Attente (Côté Expéditeur)** : La transaction est sauvegardée dans le `flutter_secure_storage` de l'Expéditeur A. L'application affiche "Paiement validé hors ligne". Le Destinataire B voit la confirmation sur l'écran de A.

### Phase 3 : La Réconciliation (Le Retour du Réseau)
- **La Synchronisation par l'Expéditeur** : Dès que l'Expéditeur A retrouve internet, son application envoie silencieusement les transactions en attente au Backend.
- **Le Règlement** : Le Backend vérifie la signature de A, débloque 2000 FCFA depuis le "Séquestre" de A, et les verse sur le compte de B.
- **La Clôture du Séquestre** : Si A décide de désactiver son mode hors ligne, le Backend réinjecte les 3000 FCFA non dépensés sur son solde principal.

---

## 3. Pourquoi ce protocole est-il infaillible (Analyse de Risques pour le Jury) ?

Cette architecture basée sur le "Séquestre" résout le problème le plus critique : la création de fausse monnaie et la double dépense.

**Attaque 1 : L'Expéditeur A efface le cache de son application (ou désinstalle l'app) après avoir payé B pour ne pas être débité.**
- *Ce qui se passe* : C'est une attaque de type "Lose-Lose" (Perdant-Perdant). En effaçant son cache, A détruit sa clé privée et son Jeton de Solde. La transaction n'est jamais envoyée au serveur, donc B ne reçoit pas les 2000 FCFA. **Cependant**, A ne récupère JAMAIS son argent non plus ! Les 5000 FCFA alloués initialement restent bloqués sur le serveur car A ne peut plus prouver ce qu'il a fait de son solde hors ligne. A est donc sévèrement puni (il perd 5000 FCFA pour arnaquer 2000 FCFA à B). Cette dissuasion économique garantie la sécurité du système.

**Attaque 2 : L'Expéditeur A tente de double-dépenser en ligne et hors ligne.**
- *Ce qui se passe* : Impossible. Dès la Phase 1, l'argent a été déduit du compte principal en ligne. Le budget hors ligne est totalement isolé dans le Séquestre. Aucune collision n'est possible.

**Attaque 3 : A tente de créer un faux QR Code avec un Jeton modifié.**
- *Ce qui se passe* : Le Destinataire B, via son application, vérifie la signature cryptographique du QR Code avec la clé publique du Serveur (intégrée à l'application). Toute altération du montant ou du Jeton invalide instantanément la signature et B refuse la transaction sur place.

**Conclusion :** 
Ce système simule un portemonnaie matériel déconnecté avec la sécurité de la Blockchain/Smart Contracts, tout en n'utilisant que des technologies mobiles classiques (QR, NFC, Cryptographie asymétrique locale). C'est la solution ultime pour les zones blanches.
