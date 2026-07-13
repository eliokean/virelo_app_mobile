import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import '../offline_sync/offline_authorization_payload.dart';
import '../crypto/offline_crypto_service.dart';

class NfcPaymentService {
  final OfflineCryptoService _cryptoService;

  NfcPaymentService(this._cryptoService);

  /// Vérifie si le NFC est disponible sur l'appareil
  Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Côté MARCHAND : Active le mode lecteur pour recevoir le paiement
  /// Attend un NDEF message contenant le payload chiffré
  Future<void> startListeningForPayment(Function(OfflineAuthorizationPayload) onPaymentReceived, Function(String) onError) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError("NFC non disponible sur cet appareil");
      return;
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        final ndef = Ndef.from(tag);
        if (ndef == null || ndef.cachedMessage == null) {
          throw Exception("Tag NFC non valide ou vide");
        }

        // On cherche le record texte contenant le payload chiffré en Base64
        for (var record in ndef.cachedMessage!.records) {
          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
            // Le premier octet est le code langue, on l'ignore (très basique pour POC)
            final payloadBytes = record.payload.skip(1).toList();
            final encryptedBase64 = utf8.decode(payloadBytes);

            // Déchiffrement et validation
            final payload = await _cryptoService.decryptPayload(encryptedBase64);
            final isValid = await _cryptoService.verifyPayload(payload);

            if (isValid) {
              onPaymentReceived(payload);
            } else {
              throw Exception("Signature NFC invalide");
            }
            break; // On a trouvé notre record
          }
        }
      } catch (e) {
        onError("Erreur de lecture NFC : ${e.toString()}");
      } finally {
        NfcManager.instance.stopSession();
      }
    });
  }

  /// Arrête la lecture NFC (Marchand)
  Future<void> stopListening() async {
    await NfcManager.instance.stopSession();
  }

  /// Côté CLIENT : Émuler une carte ou écrire sur le tag du marchand (Si le marchand a un tag passif)
  /// Note: Sur iOS, l'HCE (Host Card Emulation) est bloqué. Sur Android, il faut configurer l'ApduService natif.
  /// Pour ce POC, nous utilisons la méthode d'écriture sur Tag si le terminal agit comme une carte (inversé).
  Future<void> sendPaymentPayload(OfflineAuthorizationPayload payload, Function() onSuccess, Function(String) onError) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError("NFC non disponible sur cet appareil");
      return;
    }

    final encryptedData = await _cryptoService.encryptPayload(payload);

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          throw Exception("Impossible de transmettre le paiement (Tag non inscriptible)");
        }

        final record = NdefRecord.createText(encryptedData);
        final message = NdefMessage([record]);

        await ndef.write(message);
        onSuccess();
      } catch (e) {
        onError("Erreur d'envoi NFC : ${e.toString()}");
      } finally {
        NfcManager.instance.stopSession();
      }
    });
  }
}
