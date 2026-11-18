import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatCadMoney(BuildContext context, num amount) {
  final language = Localizations.localeOf(context).languageCode;
  final locale = language == 'fr' ? 'fr_CA' : 'en_CA';
  return NumberFormat.currency(locale: locale, symbol: r'$').format(amount);
}
