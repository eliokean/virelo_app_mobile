import 'package:virelo_core/network/api_client.dart';

class OfflineLimitInfo {
  final int kycLevel;
  final String kycLevelName;
  final bool isBanned;
  final double currentBalance;
  final double currentOfflineBalance;
  final double maxOfflineAmount;
  final double maxFixedAmount;
  final int maxPercentage;
  final double remainingAvailable;

  OfflineLimitInfo({
    required this.kycLevel,
    required this.kycLevelName,
    required this.isBanned,
    required this.currentBalance,
    required this.currentOfflineBalance,
    required this.maxOfflineAmount,
    required this.maxFixedAmount,
    required this.maxPercentage,
    required this.remainingAvailable,
  });

  factory OfflineLimitInfo.fromJson(Map<String, dynamic> json) {
    return OfflineLimitInfo(
      kycLevel: json['kyc_level'] as int? ?? 0,
      kycLevelName: json['kyc_level_name'] as String? ?? 'unknown',
      isBanned: json['is_banned'] as bool? ?? false,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      currentOfflineBalance: (json['current_offline_balance'] as num?)?.toDouble() ?? 0.0,
      maxOfflineAmount: (json['max_offline_amount'] as num?)?.toDouble() ?? 0.0,
      maxFixedAmount: (json['max_fixed_amount'] as num?)?.toDouble() ?? 0.0,
      maxPercentage: json['max_percentage'] as int? ?? 0,
      remainingAvailable: (json['remaining_available'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Vérifie si un montant peut être alloué
  bool canAllocate(double amount) {
    return amount <= remainingAvailable && amount > 0;
  }

  /// Retourne un message d'erreur explicatif si l'allocation n'est pas possible
  String? getAllocationError(double amount) {
    if (isBanned) {
      return 'Votre compte est banni. Contactez le support.';
    }

    
    if (kycLevel == 0) {
      return 'Complétez votre KYC pour accéder aux paiements hors ligne.';
    }
    
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0.';
    }
    
    if (amount > maxOfflineAmount) {
      final formattedMax = _formatAmount(maxOfflineAmount);
      return 'Montant maximum autorisé: $formattedMax XOF ou $maxPercentage% de vos fonds.';
    }
    
    if (amount > remainingAvailable) {
      final formattedRemaining = _formatAmount(remainingAvailable);
      return 'Solde disponible: $formattedRemaining XOF.';
    }
    
    return null;
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }
}

class OfflineLimitService {
  final ApiClient _apiClient;

  OfflineLimitService(this._apiClient);

  /// Récupère les informations de limites offline depuis le serveur
  Future<OfflineLimitInfo> getLimitInfo() async {
    try {
      final response = await _apiClient.dio.get('/offline/balance');
      final limitsData = response.data['limits'] as Map<String, dynamic>;
      return OfflineLimitInfo.fromJson(limitsData);
    } catch (e) {
      // En cas d'erreur, retourner une limite par défaut restrictive
      return OfflineLimitInfo(
        kycLevel: 0,
        kycLevelName: 'error',
        isBanned: false,
        currentBalance: 0,
        currentOfflineBalance: 0,
        maxOfflineAmount: 0,
        maxFixedAmount: 0,
        maxPercentage: 0,
        remainingAvailable: 0,
      );
    }
  }

  /// Valide une allocation offline avant l'envoi au serveur
  Future<Map<String, dynamic>> validateAllocation(double amount) async {
    final limitInfo = await getLimitInfo();
    
    if (!limitInfo.canAllocate(amount)) {
      return {
        'valid': false,
        'error': limitInfo.getAllocationError(amount),
        'limitInfo': limitInfo,
      };
    }

    return {
      'valid': true,
      'limitInfo': limitInfo,
    };
  }

  /// Retourne les suggestions de montants basées sur le niveau KYC
  Future<List<double>> getSuggestedAmounts() async {
    final limitInfo = await getLimitInfo();
    
    if (limitInfo.maxOfflineAmount <= 0) {
      return [];
    }

    // Générer 3 suggestions: 25%, 50%, 75% du maximum
    final suggestions = [
      limitInfo.maxOfflineAmount * 0.25,
      limitInfo.maxOfflineAmount * 0.50,
      limitInfo.maxOfflineAmount * 0.75,
    ];

    // Arrondir à des montants ronds
    return suggestions.map((amount) {
      return (amount / 1000).floor() * 1000.0;
    }).where((amount) => amount > 0).toList();
  }
}
