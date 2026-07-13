# Instructions de Compilation Sécurisée (Obfuscation)

Pour empêcher le reverse-engineering de l'application Virelo, il est impératif de compiler les versions de production (APK, AppBundle, ou IPA) avec l'obfuscation activée.

## Pourquoi faire ça ?
Le code Dart compilé contient beaucoup d'informations en clair (noms de variables, fonctions, noms de classes). Un attaquant pourrait extraire l'APK et décompiler le code source pour comprendre notre mécanisme de chiffrement hors-ligne. L'obfuscation transforme `decryptPayload(String data)` en quelque chose comme `a(String b)`, rendant le code illisible.

## Commande Android
```bash
flutter build apk --obfuscate --split-debug-info=./debug_info
```

## Commande iOS
```bash
flutter build ipa --obfuscate --split-debug-info=./debug_info
```

## Attention : Stack Traces
Si votre application plante en production (Crashlytics, Sentry), la trace d'erreur sera illisible. Vous devrez utiliser le dossier `debug_info` généré lors de la compilation pour "dés-obfusquer" les erreurs avec la commande suivante :
```bash
flutter symbolize -i <fichier-stack-trace> -d ./debug_info
```
