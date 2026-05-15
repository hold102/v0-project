/*
 * fx_service.dart — Foreign exchange rates
 *
 * Fetches the latest USD-based rates from exchangerate-api.com (free tier,
 * no API key required) and caches them in memory for the session.
 * `convert(amount, from, to)` works between any two supported currencies.
 *
 * Falls back to a small hardcoded table when the API is unreachable so the
 * app still works offline (rates are approximate then, but UI doesn't break).
 */
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FxService {
  static final FxService _instance = FxService._();
  factory FxService() => _instance;
  FxService._();

  // Rates relative to USD (1 USD = X target)
  Map<String, double> _rates = const {
    'USD': 1.0,
    'MYR': 4.7,
    'SGD': 1.34,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 150.0,
    'CNY': 7.2,
    'AUD': 1.5,
    'IDR': 15800.0,
    'THB': 36.5,
  };
  DateTime? _fetchedAt;
  Future<void>? _inflight;

  static const supportedCurrencies = [
    'MYR',
    'USD',
    'EUR',
    'SGD',
    'GBP',
    'JPY',
    'CNY',
    'AUD',
    'IDR',
    'THB',
  ];

  // Pretty symbol for the dropdown UI.
  static String symbolFor(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'MYR':
        return 'RM';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'IDR':
        return 'Rp';
      case 'THB':
        return '฿';
      default:
        return code;
    }
  }

  Future<void> ensureLoaded() {
    if (_inflight != null) return _inflight!;
    if (_fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!).inHours < 6) {
      return Future.value();
    }
    _inflight = _fetch();
    return _inflight!;
  }

  Future<void> _fetch() async {
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final rates = (json['rates'] as Map<String, dynamic>?) ?? {};
        final next = <String, double>{};
        rates.forEach((k, v) {
          if (v is num) next[k] = v.toDouble();
        });
        if (next.isNotEmpty) {
          _rates = next;
          _fetchedAt = DateTime.now();
        }
      }
    } catch (_) {
      // Keep hardcoded fallback rates
    } finally {
      _inflight = null;
    }
  }

  // Convert `amount` from `from` to `to`. Returns null when either currency
  // is unsupported. Same-currency conversion returns the amount as-is.
  double? convert(double amount, String from, String to) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    if (f == t) return amount;
    final fr = _rates[f];
    final tr = _rates[t];
    if (fr == null || tr == null) return null;
    return amount * (tr / fr);
  }

  // Format like "€50.00" or "RM 250.00"
  String format(double amount, String currency) {
    final sym = symbolFor(currency);
    final needsSpace = sym.length > 1; // e.g. "RM ", "S$ "
    final body = amount.toStringAsFixed(2);
    return needsSpace ? '$sym $body' : '$sym$body';
  }
}
