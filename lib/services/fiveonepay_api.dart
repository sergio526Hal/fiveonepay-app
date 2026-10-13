import 'dart:convert';

import 'package:http/http.dart' as http;

class OperatorItem {
  final String operatorName;
  final String label;
  final int minAmount;
  final int maxAmount;
  final bool isActive;

  const OperatorItem({
    required this.operatorName,
    required this.label,
    required this.minAmount,
    required this.maxAmount,
    required this.isActive,
  });

  factory OperatorItem.fromJson(Map<String, dynamic> json) {
    final name = (json['operator'] ?? json['code'] ?? 'MVOLA').toString();
    final label = (json['label'] ?? json['name'] ?? name).toString();
    final minAmount =
        (json['min_amount'] ?? json['minimum_amount'] ?? 0) as num? ?? 0;
    final maxAmount =
        (json['max_amount'] ?? json['maximum_amount'] ?? 0) as num? ?? 0;
    final active = json['is_active'] ?? json['active'] ?? true;

    return OperatorItem(
      operatorName: name,
      label: label,
      minAmount: minAmount.toInt(),
      maxAmount: maxAmount.toInt(),
      isActive: active == true,
    );
  }
}

class FiveOnePayApi {
  static const String _baseUrl = 'http://localhost:3000';

  static Future<List<OperatorItem>> fetchOperators() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/operators'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 400) {
        throw Exception(
          'Impossible de charger les opérateurs (${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Réponse API invalide pour les opérateurs.');
      }

      return decoded
          .whereType<Map>()
          .map((item) => OperatorItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.isActive)
          .toList();
    } catch (_) {
      return const [
        OperatorItem(
          operatorName: 'MVOLA',
          label: 'MVola',
          minAmount: 1000,
          maxAmount: 1500000,
          isActive: true,
        ),
        OperatorItem(
          operatorName: 'ORANGE',
          label: 'Orange Money',
          minAmount: 1000,
          maxAmount: 1500000,
          isActive: true,
        ),
        OperatorItem(
          operatorName: 'AIRTEL',
          label: 'Airtel Money',
          minAmount: 1000,
          maxAmount: 1500000,
          isActive: true,
        ),
      ];
    }
  }

  static Future<Map<String, dynamic>> createPayment({
    required int amount,
    required String operatorName,
    String? payerNumber,
    String description = 'Paiement FiveOne Pay',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'operator': operatorName,
        'description': description,
        if (payerNumber != null && payerNumber.trim().isNotEmpty)
          'payerNumber': payerNumber.trim(),
      }),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['message'] ?? 'Erreur lors de la création du paiement.')
          : 'Erreur lors de la création du paiement.';
      throw Exception(message);
    }

    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'status': 'success'};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode >= 400) {
        throw Exception('Connexion impossible. Vérifiez vos identifiants.');
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'status': 'success', 'message': 'Connexion réussie'};
    } catch (_) {
      return {
        'status': 'demo',
        'message': 'Mode démo activé : la connexion est validée localement.',
        'user': {'email': email},
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String country,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'country': country,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception(
          'Inscription impossible. Vérifiez les informations saisies.',
        );
      }

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'status': 'success', 'message': 'Inscription réussie'};
    } catch (_) {
      return {
        'status': 'demo',
        'message': 'Mode démo activé : votre compte a été créé localement.',
      };
    }
  }
}
