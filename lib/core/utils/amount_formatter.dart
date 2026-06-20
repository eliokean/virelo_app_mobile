class AmountFormatter {
  AmountFormatter._();

  /// "12329.5" → "12 329"  (partie entière, espace comme séparateur)
  static String formatWhole(double amount) {
    final intPart = amount.toInt();
    final str = intPart.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('\u202F'); // espace fine
      result.write(str[i]);
    }
    return result.toString();
  }

  /// "12329.5" → "12 329,50 XOF"
  static String formatFull(double amount, {String currency = 'XOF'}) {
    final whole    = formatWhole(amount.floorToDouble());
    final decimals = ((amount - amount.floorToDouble()) * 100).round();
    return '$whole,${decimals.toString().padLeft(2, '0')} $currency';
  }

  /// Pour afficher la variation : "+4,2%" ou "-1,5%"
  static String formatVariation(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
