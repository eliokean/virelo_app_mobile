class ApiConstants {
  // L'IP locale utilisée pour tester avec le backend Laravel (hors Docker)
  static const String baseUrl = 'https://stimulate-bladder-hurry.ngrok-free.dev';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  
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
  static const String initiateRecharge = '/recharges/initiate';

  // Sync / Telecollecte
  static const String syncTelecollecte = '/sync/telecollecte';
}
