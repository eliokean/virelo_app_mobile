import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:virelo_core/crypto/offline_crypto_service.dart';
import 'package:virelo_core/offline_sync/offline_storage_service.dart';
import 'package:cryptography/cryptography.dart';

@GenerateNiceMocks([MockSpec<OfflineStorageService>()])
import 'offline_crypto_service_test.mocks.dart';

void main() {
  group('OfflineCryptoService', () {
    late OfflineCryptoService cryptoService;
    late MockOfflineStorageService mockStorageService;
    late Ed25519 algorithm;
    late SimpleKeyPair keyPair;

    setUp(() async {
      algorithm = Ed25519();
      keyPair = await algorithm.newKeyPair();
      
      mockStorageService = MockOfflineStorageService();
      
      when(mockStorageService.getKeyPair(any)).thenAnswer((_) async => keyPair);
      when(mockStorageService.incrementAndGetSequenceNumber()).thenAnswer((_) async => 1);
      
      final publicKey = await keyPair.extractPublicKey();
      when(mockStorageService.getPublicKeyBase64()).thenAnswer((_) async => base64Encode(publicKey.bytes));

      cryptoService = OfflineCryptoService(mockStorageService);
    });

    test('generateSignedPayload should create a valid payload', () async {
      final payload = await cryptoService.generateSignedPayload(
        clientId: 'client-123',
        merchantId: 'merchant-456',
        amount: 1500.0,
      );

      expect(payload.clientId, 'client-123');
      expect(payload.merchantId, 'merchant-456');
      expect(payload.amount, 1500.0);
      expect(payload.sequenceNumber, 1);
      expect(payload.clientSignature, isNotEmpty);
      expect(payload.clientPublicKey, isNotEmpty);
    });

    test('verifyPayload should return true for valid payload', () async {
      final payload = await cryptoService.generateSignedPayload(
        clientId: 'client-123',
        merchantId: 'merchant-456',
        amount: 1500.0,
      );

      final isValid = await cryptoService.verifyPayload(payload);
      expect(isValid, isTrue);
    });

    test('signMerchantReceipt produces a signature verifiable against MRCPT string', () async {
      final res = await cryptoService.signMerchantReceipt(
        clientDataToSign: 'client-123:merchant-456:1500.0:1:ts:uuid:pub:vu',
        merchantId: '42',
        merchantTimestamp: '2026-09-01T10:00:05Z',
      );

      expect(res['signature'], isNotEmpty);
      expect(res['publicKey'], isNotEmpty);

      final pub = SimplePublicKey(
        base64Decode(res['publicKey']!),
        type: KeyPairType.ed25519,
      );
      final ok = await algorithm.verify(
        utf8.encode('MRCPT:client-123:merchant-456:1500.0:1:ts:uuid:pub:vu:42:2026-09-01T10:00:05Z'),
        signature: Signature(base64Decode(res['signature']!), publicKey: pub),
      );
      expect(ok, isTrue);
    });
  });
}
