import 'package:intl/intl.dart';

class CurrencyUtils {
  static double usdToIdr(double usd) => usd * 16000;
  static double convertFromIdr(double idr, String currency) {
    switch (currency) {
      case "USD":
        return idr / 16000;
      case "JPY":
        return idr / 110;
      default:
        return idr;
    }
  }

  static String symbol(String code) {
    switch (code) {
      case "USD":
        return "\$";
      case "JPY":
        return "¥";
      default:
        return "Rp";
    }
  }

  static String format(double amount, String code) {
    switch (code) {
      case "USD":
        return NumberFormat.currency(
          locale: "en_US",
          symbol: "",
          decimalDigits: 2,
        ).format(amount);
      case "JPY":
        return NumberFormat.currency(
          locale: "ja_JP",
          symbol: "",
          decimalDigits: 0,
        ).format(amount);
      case "IDR":
      default:
        return NumberFormat.currency(
          locale: "id_ID",
          symbol: "",
          decimalDigits: 0,
        ).format(amount);
    }
  }

  static String formatIdr(double idr) {
    final formatter = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp",
      decimalDigits: 0,
    );
    return formatter.format(idr);
  }
}
