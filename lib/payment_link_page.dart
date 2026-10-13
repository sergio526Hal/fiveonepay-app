
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentLinkPage extends StatefulWidget {
  const PaymentLinkPage({super.key});

  @override
  State<PaymentLinkPage> createState() => _PaymentLinkPageState();
}

class _PaymentLinkPageState extends State<PaymentLinkPage> {
  // Backend Node.js mandeha amin'ny ordinateur-nao
  static const String backendUrl = 'http://localhost:3000';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _operator = 'MVOLA';
  bool _loading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  Future<void> _createPaymentLink() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(
      _amountController.text.trim().replaceAll(' ', ''),
    );

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Ampidiro ny montant valide amin’ny Ariary.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/payment-links'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'description': _descriptionController.text.trim(),
          'operator': _operator,
        }),
      );

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Réponse inattendue du serveur.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          decoded['message']?.toString() ??
              'Impossible de créer le lien de paiement.',
        );
      }

      final paymentUrl = decoded['url']?.toString() ?? '';

      if (paymentUrl.isEmpty) {
        throw Exception(
          'Lien non reçu dans la réponse FiveOne Pay.',
        );
      }

      if (mounted) {
        setState(() {
          _result = decoded;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error
              .toString()
              .replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyPaymentLink() async {
    final url = _result?['url']?.toString();

    if (url == null || url.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien copié avec succès !'),
        ),
      );
    }
  }

  Future<void> _openPaymentLink() async {
    final url = _result?['url']?.toString();

    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'pay.fiveonepay.com') {
      setState(() {
        _errorMessage = 'URL de paiement invalide.';
      });
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir le lien.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final paymentUrl = result?['url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Liens de paiement'),
        backgroundColor: const Color(0xFF092744),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.link_rounded,
                size: 52,
                color: Color(0xFF123B60),
              ),
              const SizedBox(height: 12),
              const Text(
                'Créer un lien de paiement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF092744),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Créez un lien réutilisable pour un montant fixe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 1,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Montant (Ar)',
                            hintText: 'Ex. : 30000',
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final amount = int.tryParse(
                              (value ?? '').trim().replaceAll(' ', ''),
                            );

                            if (amount == null || amount <= 0) {
                              return 'Entrez un montant entier positif.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Ex. : Gourde inox 1L',
                            prefixIcon: Icon(Icons.description_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Entrez une description.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: _operator,
                          decoration: const InputDecoration(
                            labelText: 'Opérateur',
                            prefixIcon: Icon(Icons.phone_android),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'MVOLA',
                              child: Text('MVola'),
                            ),
                            DropdownMenuItem(
                              value: 'ORANGE_MONEY',
                              child: Text('Orange Money'),
                            ),
                            DropdownMenuItem(
                              value: 'AIRTEL_MONEY',
                              child: Text('Airtel Money'),
                            ),
                          ],
                          onChanged: _loading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _operator = value;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 22),

                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        FilledButton.icon(
                          onPressed:
                              _loading ? null : _createPaymentLink,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_link),
                          label: Text(
                            _loading
                                ? 'Création en cours...'
                                : 'Créer le lien de paiement',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF123B60),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (result != null) ...[
                const SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lien créé avec succès',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(
                          '${result['amount'] ?? ''} Ar',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF123B60),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Description : '
                          '${result['description'] ?? '-'}',
                        ),
                        Text(
                          'Opérateur : '
                          '${result['operator'] ?? '-'}',
                        ),
                        Text(
                          'Environnement : '
                          '${result['environment'] ?? '-'}',
                        ),
                        Text(
                          'Nombre de paiements : '
                          '${result['payments_count'] ?? 0}',
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Votre lien de paiement :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        SelectableText(
                          paymentUrl,
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: _copyPaymentLink,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copier le lien'),
                        ),
                        const SizedBox(height: 8),

                        FilledButton.icon(
                          onPressed: _openPaymentLink,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ouvrir le lien'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
