import 'dart:convert';
import 'dart:typed_data';
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
  /// Supporte à la fois le HCE (IsoDep téléphone-à-téléphone) et les Tags/Cartes NFC physiques (NDEF)
  Future<void> startListeningForPayment(Function(OfflineAuthorizationPayload) onPaymentReceived, Function(String) onError) async {
    bool isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError("NFC non disponible sur cet appareil");
      return;
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        // 1. Tenter la lecture via IsoDep (Host Card Emulation / Smartphone à Smartphone)
        final isodep = IsoDep.from(tag);
        if (isodep != null) {
          // APDU Select AID: CLA=00, INS=A4, P1=04, P2=00, Lc=07, AID=F0010203040506, Le=00
          final selectAidApdu = Uint8List.fromList([
            0x00, 0xA4, 0x04, 0x00, 0x07,
            0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
            0x00
          ]);

          final response = await isodep.transceive(data: selectAidApdu);
          if (response.length >= 2 &&
              response[response.length - 2] == 0x90 &&
              response[response.length - 1] == 0x00) {
            
            final payloadBytes = response.sublist(0, response.length - 2);
            if (payloadBytes.isNotEmpty) {
              final encryptedBase64 = utf8.decode(payloadBytes);
              final payload = await _cryptoService.decryptPayload(encryptedBase64);
              final isValid = await _cryptoService.verifyPayload(payload);

              if (isValid) {
                onPaymentReceived(payload);
                return;
              } else {
                throw Exception("Signature NFC invalide");
              }
            }
          }
        }

        // 2. Tenter la lecture via NDEF classique (Cartes / Badges / Stickers physiques)
        final ndef = Ndef.from(tag);
        if (ndef != null && ndef.cachedMessage != null) {
          for (var record in ndef.cachedMessage!.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
              final payloadBytes = record.payload.skip(1).toList();
              final encryptedBase64 = utf8.decode(payloadBytes);

              final payload = await _cryptoService.decryptPayload(encryptedBase64);
              final isValid = await _cryptoService.verifyPayload(payload);

              if (isValid) {
                onPaymentReceived(payload);
                return;
              } else {
                throw Exception("Signature NFC invalide");
              }
            }
          }
        }

        throw Exception("Aucune donnée de paiement valide reçue par NFC");
      } catch (e) {
        onError("Erreur de lecture NFC : ${e.toString().replaceAll('Exception: ', '')}");
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
