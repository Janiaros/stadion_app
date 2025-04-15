import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String baseUrl = 'https://stadionspeck.de';

  /// Versucht die [action] bis zu [attempts] Mal (mit [delay] zwischen den Versuchen).
  static Future<T> _retry<T>(
      Future<T> Function() action, {
        int attempts = 3,
        Duration delay = const Duration(seconds: 1),
      }) async {
    int currentAttempt = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        currentAttempt++;
        print("Retry attempt $currentAttempt failed with error: $error");
        if (currentAttempt >= attempts) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
  }


  /// Führt eine GET-Anfrage an [endpoint] aus und gibt das decodierte JSON zurück.
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _retry(() async {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception('GET-Fehler: ${response.statusCode} ${response.body}');
      }
    });
  }

  /// Führt eine POST-Anfrage an [endpoint] mit dem übergebenen [body] aus.
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _retry(() async {
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception('POST-Fehler: ${response.statusCode} ${response.body}');
      }
    });
  }

  /// Führt eine PUT-Anfrage an [endpoint] mit dem übergebenen [body] aus.
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _retry(() async {
      final response = await http
          .put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception('PUT-Fehler: ${response.statusCode} ${response.body}');
      }
    });
  }

  /// Führt eine DELETE-Anfrage an [endpoint] aus.
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await _retry(() async {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 300) {
        return decoded;
      } else {
        throw Exception('DELETE-Fehler: ${response.statusCode} ${response.body}');
      }
    });
  }
}
