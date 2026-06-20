# Résumé de l'implémentation du transfert

Le flux d'envoi d'argent a été complètement restructuré pour permettre la sélection du bénéficiaire en priorité.

## Modifications apportées

1. **Intégration des contacts système**
   - Ajout du package `flutter_contacts` et `permission_handler`.
   - Les autorisations de lecture des contacts ont été définies pour Android et iOS.

2. **Création de la page de sélection**
   - La nouvelle page `TransferContactPage` s'affiche lorsqu'on clique sur "Envoyer".
   - Elle inclut une barre de recherche.
   - Elle intègre un bouton `Ouvrir les contacts` qui sollicite la permission de l'utilisateur et affiche le carnet d'adresses en temps réel.
   - Une liste factice ("Récents") est affichée par défaut si les contacts n'ont pas encore été chargés.

3. **Mise à jour de la page de montant**
   - La page `TransferAmountPage` a été adaptée pour accepter en paramètre le nom (ou le numéro) de la personne sélectionnée.
   - Elle affiche un petit bloc informatif ("Vers [Nom]") juste au-dessus du montant à transférer, clarifiant ainsi le destinataire pour l'utilisateur.

## Comment tester
1. Lancez l'application en mode débogage avec `flutter run`.
2. Appuyez sur le bouton "Envoyer".
3. Cliquez sur "Ouvrir les contacts" : acceptez la permission demandée.
4. Sélectionnez un contact dans la liste, ou utilisez la liste "Récents" affichée par défaut.
5. Saisissez ensuite le montant à envoyer sur l'écran suivant.
