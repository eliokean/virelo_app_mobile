class OfflineAuthorizationPayload {
  final String clientId;
  final String merchantId;
  final double amount;
  final int sequenceNumber;
  final String timestamp;
  final String uuid;
  final String clientPublicKey;
  final String clientSignature;
  final String validUntil;

  OfflineAuthorizationPayload({
    required this.clientId,
    required this.merchantId,
    required this.amount,
    required this.sequenceNumber,
    required this.timestamp,
    required this.uuid,
    required this.clientPublicKey,
    required this.clientSignature,
    required this.validUntil,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'merchantId': merchantId,
        'amount': amount,
        'sequenceNumber': sequenceNumber,
        'timestamp': timestamp,
        'uuid': uuid,
        'clientPublicKey': clientPublicKey,
        'clientSignature': clientSignature,
        'validUntil': validUntil,
      };

  factory OfflineAuthorizationPayload.fromJson(Map<String, dynamic> json) {
    return OfflineAuthorizationPayload(
      clientId: json['clientId'] as String,
      merchantId: json['merchantId'] as String,
      amount: (json['amount'] as num).toDouble(),
      sequenceNumber: json['sequenceNumber'] as int,
      timestamp: json['timestamp'] as String,
      uuid: json['uuid'] as String? ?? '', // Support retrocompatibilité si absent
      clientPublicKey: json['clientPublicKey'] as String,
      clientSignature: json['clientSignature'] as String,
      validUntil: json['validUntil'] as String? ?? '', 
    );
  }

  /// Chaîne canonique EXACTE à signer.
  ///
  /// Elle DOIT rester strictement identique à
  /// `App\Modules\Sync\Services\CryptoLogic::buildDataToSign()` côté backend
  /// Laravel : mêmes champs, même ordre, séparateur `:`, et même format de
  /// montant (représentation décimale courte, avec `.0` forcé pour un entier).
  /// Toute modification ici impose la même modification côté serveur ET un
  /// redéploiement coordonné client/serveur.
  String getDataToSign() {
    return '$clientId:$merchantId:${canonicalAmount(amount)}'
        ':$sequenceNumber:$timestamp:$uuid:$clientPublicKey:$validUntil';
  }

  /// Reproduit `(string)(float)$amount` + ajout de `.0` si entier (règle PHP).
  static String canonicalAmount(double amount) {
    final s = amount.toString();
    return s.contains('.') ? s : '$s.0';
  }
}
