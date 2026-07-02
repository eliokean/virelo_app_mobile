# Architecture Alternative : Système Dual-Offline Basé sur les Canaux d'État Blockchain (State Channels)

## 1. Introduction et Philosophie du Système
Dans cette architecture alternative, le tiers de confiance central (serveur) est remplacé par une Blockchain décentralisée publique ou de consortium (ex: réseau compatible EVM comme Ethereum/Polygon ou Hyperledger Fabric).

Pour surmonter l'impossibilité d'exécuter un consensus réseau en mode hors ligne, le système transpose le concept de **Canaux d'État (State Channels)** au paiement mobile. Le smartphone n'exécute pas la blockchain ; il agit comme un coffre-fort cryptographique local capable de signer des transitions d'état intermédiaires qui seront résolues de manière immuable et transparente sur la blockchain à la reconnexion.

## 2. Le Mécanisme du Séquestre Préalable (Pre-funded Model)
Contrairement au modèle de chèque asynchrone, l'utilisation de la blockchain sans wallet de secours impose un mécanisme de mise en séquestre préalable des fonds pour rendre le système mathématiquement inviolable, même si l'utilisateur abandonne l'application après une fraude.

```text
[ PHASE EN LIGNE ]
Compte global Blockchain (100 €) ───> Débit immédiat de 30 € ───> Smart Contract Séquestre
                                                                           │
                                                                           ▼
[ PHASE HORS LIGNE ]                                            Génère un Jeton Certifié
Téléphone Marchand <─── Transfert du Jeton (NFC/QR) <─── Stocké dans flutter_secure_storage
(Soustraction locale)
```

- **Le Verrouillage (On-Chain)** : Avant de passer hors ligne, le client interagit avec un Smart Contract. S'il dispose de 100 € sur la blockchain, il décide de bloquer 30 € pour ses dépenses hors ligne. Le Smart Contract fige immédiatement ces 30 € (le solde en ligne passe à 70 €) et émet un certificat de dépôt numérique cryptographique.
- **L'Isolation complète** : Les 30 € étant bloqués sur la blockchain, le client peut utiliser un autre appareil connecté : il ne pourra jamais dépenser plus que les 70 € restants en ligne. La collision entre le monde en ligne et le monde hors ligne est structurellement impossible.

## 3. Gestion de la Double Dépense et de la Suppression du Cache
Si un utilisateur malveillant vide son cache ou désinstalle son application Flutter pour réinitialiser frauduleusement son solde local à 30 € :

- **La Perte de la Clé** : En effaçant les données sécurisées (`flutter_secure_storage`), il détruit sa clé privée locale et le certificat de dépôt. Sans ces éléments, l'application est incapable de générer une signature valide. Le terminal du marchand refuse instantanément le paiement NFC/QR. L'utilisateur a détruit ses propres fonds hors ligne, la blockchain est protégée.
- **La Théorie des Jeux et le Slashing (Pénalité)** : Si l'utilisateur parvient à cloner sa clé sur deux appareils pour dépenser ses 30 € deux fois hors ligne (30 € chez le Marchand A et 30 € chez le Marchand B) :
  1. Lors de la reconnexion, le Marchand A soumet sa preuve au Smart Contract. Le Smart Contract lui verse 30 € issus du séquestre. Le séquestre est vide.
  2. Le Marchand B soumet sa preuve. Le Smart Contract détecte une rupture de séquence (deux transactions avec le même numéro d'index).
  3. **Le verdict automatique** : Le Smart Contract exécute une fonction de Slashing. Il confisque automatiquement le dépôt de garantie général (ou le solde restant de 70 €) que le client possédait sur son compte principal en ligne pour indemniser le Marchand B. La fraude devient financièrement suicidaire pour l'utilisateur.

## 4. Cycle de Vie d'une Transaction Blockchain Offline
- **Étape 1 : Le Paiement Hors Ligne (Client <-> Marchand)**
Le Marchand transmet un défi (Nonce + son adresse publique blockchain). L'application Flutter du client décrémente le solde local dans le stockage sécurisé, incrémente le numéro de séquence, et génère une signature compatible Web3 (généralement au format ECDSA secp256k1).
- **Étape 2 : La Clôture du Canal (Reconnexion)**
Dès que le Marchand retrouve internet, il pousse le reçu au Smart Contract. Le Smart Contract utilise la fonction native de la blockchain `ecrecover` pour authentifier mathématiquement la signature du client sans intermédiaire humain ou bancaire. Les fonds du séquestre sont libérés vers le wallet du marchand.

## 5. Structure du Smart Contract de Règlement (Exemple Solidity)
Voici la logique du Smart Contract à déployer sur un réseau compatible EVM (ex: Hardhat/Ethereum) :

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OfflinePaymentChannel {
    struct Channel {
        address client;
        uint256 balanceLocked;
        uint256 lastSequence;
        bool isActive;
    }

    mapping(address => Channel) public channels;
    mapping(bytes32 => bool) public usedNonces;

    // Étape 1 : Le client verrouille ses fonds avant de se déconnecter
    function lockFunds() external payable {
        require(msg.value > 0, "Montant invalide");
        require(!channels[msg.sender].isActive, "Canal deja actif");

        channels[msg.sender] = Channel({
            client: msg.sender,
            balanceLocked: msg.value,
            lastSequence: 0,
            isActive: true
        });
    }

    // Étape 2 : Le marchand se reconnecte et réclame les fonds avec la signature du client
    function claimOfflinePayment(
        address client,
        address merchant,
        uint256 amount,
        uint256 sequence,
        bytes32 nonce,
        bytes memory signature
    ) external {
        Channel storage channel = channels[client];
        require(channel.isActive, "Canal inexistant ou ferme");
        require(!usedNonces[nonce], "Attaque par rejeu : Nonce deja utilise");
        require(sequence > channel.lastSequence, "Fraude de sequence detectee");
        require(amount <= channel.balanceLocked, "Solde sequestre insuffisant");

        // Reconstruire le message haché qui a été signé par l'application Flutter
        bytes32 messageHash = keccak256(abi.encodePacked(client, merchant, amount, sequence, nonce));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        // Récupérer l'adresse de celui qui a signé
        address signer = recoverSigner(ethSignedMessageHash, signature);
        require(signer == client, "Signature invalide ou falsifiee");

        // Exécution du paiement
        usedNonces[nonce] = true;
        channel.lastSequence = sequence;
        channel.balanceLocked -= amount;

        payable(merchant).transfer(amount);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Longueur de signature invalide");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
```
