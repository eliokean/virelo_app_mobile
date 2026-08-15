class ApiConstants {
  /// Base URL configurable via variable d'environnement au lancement / build :
  /// flutter run --dart-define=API_BASE_URL=https://votre-url-ngrok.ngrok-free.dev
  /// ou
  /// flutter run --dart-define=NGROK_URL=https://votre-url-ngrok.ngrok-free.dev
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment(
      'NGROK_URL',
      defaultValue: 'https://backend-virelo.onrender.com',
    ),
  );

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String forgotPin = '/auth/forgot-pin';
  static const String resetPin = '/auth/reset-pin';
  
  // Transactions
  static const String processOffline = '/transactions/process-offline';
  
  // Biométrie
  static const String biometricBind = '/auth/biometric-bind';

  // Merchants endpoints
  static const String merchants = '/merchants';
  static const String linkTerminal = '/merchants/{id}/terminals';
  static const String checkTerminalStatus = '/terminals/{id}/status';

  // Wallet endpoints
  static const String walletBalance = '/wallets/balance';
  static const String walletHistory = '/wallets/history';
  static const String initiateRecharge = '/recharges/initiate';

  // Sync / Telecollecte / Offline
  static const String syncTelecollecte = '/sync/telecollecte';
  static const String offlineStatus = '/offline/status';
}
