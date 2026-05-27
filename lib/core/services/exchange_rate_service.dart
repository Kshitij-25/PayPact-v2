import 'package:dio/dio.dart';

class ExchangeRateService {
  ExchangeRateService(this._dio);
  final Dio _dio;

  // In-memory cache: base -> {target: rate}
  final Map<String, Map<String, double>> _cache = {};

  Future<double> getRate(String from, String to) async {
    if (from == to) return 1.0;
    if (!_cache.containsKey(from)) {
      await _fetchRates(from);
    }
    final rate = _cache[from]?[to];
    if (rate == null) {
      throw Exception('Exchange rate not available for $from → $to');
    }
    return rate;
  }

  Future<void> _fetchRates(String base) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://open.er-api.com/v6/latest/$base',
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    final data = response.data;
    if (data == null || data['result'] != 'success') {
      throw Exception('Failed to fetch exchange rates for $base');
    }
    final rates = data['rates'] as Map<String, dynamic>;
    _cache[base] = rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}