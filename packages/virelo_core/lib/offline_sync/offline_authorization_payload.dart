class OfflineAuthorizationPayload {
  final String clientId;
  final String merchantId;
  final double amount;
  final int sequenceNumber;
  final String timestamp;
  final String clientPublicKey;
  final String clientSignature;

  OfflineAuthorizationPayload({
    required this.clientId,
    required this.merchantId,
    required this.amount,
    required this.sequenceNumber,
    required this.timestamp,
    required this.clientPublicKey,
    required this.clientSignature,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'merchantId': merchantId,
        'amount': amount,
        'sequenceNumber': sequenceNumber,
        'timestamp': timestamp,
        'clientPublicKey': clientPublicKey,
        'clientSignature': clientSignature,
      };

  factory OfflineAuthorizationPayload.fromJson(Map<String, dynamic> json) {
    return OfflineAuthorizationPayload(
      clientId: json['clientId'] as String,
      merchantId: json['merchantId'] as String,
      amount: (json['amount'] as num).toDouble(),
      sequenceNumber: json['sequenceNumber'] as int,
      timestamp: json['timestamp'] as String,
      clientPublicKey: json['clientPublicKey'] as String,
      clientSignature: json['clientSignature'] as String,
    );
  }

  /// Retourne les données brutes sous forme de String pour la signature
  String getDataToSign() {
    return '$clientId:$merchantId:$amount:$sequenceNumber:$timestamp:$clientPublicKey';
  }
}
