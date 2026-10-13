import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'payment_link_page.dart';

const blue = Color(0xFF155EEF);
const darkBlue = Color(0xFF102A56);
const ink = Color(0xFF101828);
const muted = Color(0xFF667085);
const pageBg = Color(0xFFF7F9FC);

void main() {
  runApp(const FiveOnePayApp());
}

class FiveOnePayApp extends StatelessWidget {
  const FiveOnePayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiveOne Pay',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: pageBg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          elevation: 0,
        ),
      ),
      home: const LandingPage(),
    );
  }
}

// ============================================================
// ACCUEIL
// ============================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();

  void _openPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentPage()),
    );
  }

  void _openPaymentLink(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentLinkPage()),
    );
  }

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _NavigationBar(
                    mobile: mobile,
                    onPay: () => _openPayment(context),
                    onCreateLink: () => _openPaymentLink(context),
                    onServices: () => _scrollToSection(_servicesKey),
                    onHowItWorks: () => _scrollToSection(_howItWorksKey),
                  ),
                  _HeroSection(
                    mobile: mobile,
                    onPay: () => _openPayment(context),
                    onCreateLink: () => _openPaymentLink(context),
                  ),
                  const _TrustSection(),
                  _ServicesSection(sectionKey: _servicesKey),
                  _HowItWorksSection(
                    sectionKey: _howItWorksKey,
                    onPay: () => _openPayment(context),
                    onCreateLink: () => _openPaymentLink(context),
                  ),
                  _Footer(
                    onPay: () => _openPayment(context),
                    onCreateLink: () => _openPaymentLink(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION
// ============================================================

class _NavigationBar extends StatelessWidget {
  final bool mobile;
  final VoidCallback onPay;
  final VoidCallback onCreateLink;
  final VoidCallback onServices;
  final VoidCallback onHowItWorks;

  const _NavigationBar({
    required this.mobile,
    required this.onPay,
    required this.onCreateLink,
    required this.onServices,
    required this.onHowItWorks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 48, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FiveOne Pay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkBlue,
                ),
              ),
              Text(
                'PAYMENT SOLUTIONS',
                style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: muted),
              ),
            ],
          ),
          const Spacer(),
          if (!mobile) ...[
            TextButton(
              onPressed: onServices,
              child: const Text('Nos solutions'),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onHowItWorks,
              child: const Text('Comment ça marche'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onCreateLink,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Créer un lien'),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton(
            onPressed: onPay,
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 13 : 20,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(mobile ? 'Payer' : 'Effectuer un paiement'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO SECTION
// ============================================================

class _HeroSection extends StatelessWidget {
  final bool mobile;
  final VoidCallback onPay;
  final VoidCallback onCreateLink;

  const _HeroSection({
    required this.mobile,
    required this.onPay,
    required this.onCreateLink,
  });

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withAlpha(55)),
          ),
          child: const Text(
            'SOLUTION DE PAIEMENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          'Les paiements,\nsimplement.',
          style: TextStyle(
            color: Colors.white,
            fontSize: mobile ? 38 : 58,
            fontWeight: FontWeight.w800,
            height: 1.13,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Découvrez une expérience de paiement conçue '
          'pour faciliter vos transactions en Ariary '
          'avec les opérateurs Mobile Money disponibles.',
          style: TextStyle(color: Color(0xFFDCE7FF), fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Commencer un paiement'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: darkBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 19,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onCreateLink,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Créer un lien de paiement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 19,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 24 : 70,
        vertical: mobile ? 45 : 75,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, Color(0xFF174A91), blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroText(),
                    const SizedBox(height: 38),
                    const _PaymentPreview(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: _buildHeroText()),
                    const SizedBox(width: 55),
                    const Expanded(flex: 5, child: _PaymentPreview()),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============================================================
// APERÇU DU PAIEMENT
// ============================================================

class _PaymentPreview extends StatelessWidget {
  const _PaymentPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 410),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: blue, size: 20),
              SizedBox(width: 9),
              Text(
                'Votre espace de paiement',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          const Text('Montant', style: TextStyle(color: muted)),
          const SizedBox(height: 7),
          const Text(
            '50 000 Ar',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEAECF0)),
          const SizedBox(height: 12),
          const _OperatorTile(
            icon: Icons.phone_android,
            title: 'MVola',
            subtitle: 'Mobile Money',
            color: Color(0xFF16834A),
          ),
          const SizedBox(height: 12),
          const _OperatorTile(
            icon: Icons.phone_android,
            title: 'Orange Money',
            subtitle: 'Mobile Money',
            color: Color(0xFFED7900),
          ),
          const SizedBox(height: 12),
          const _OperatorTile(
            icon: Icons.shield_outlined,
            title: 'Paiement protégé',
            subtitle: 'Redirection vers la page de paiement',
            color: blue,
          ),
          const SizedBox(height: 19),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Les opérateurs disponibles sont vérifiés par le serveur.',
                    style: TextStyle(color: darkBlue, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OperatorTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: ink),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: color, size: 20),
      ],
    );
  }
}

// ============================================================
// SECTION CONFIANCE
// ============================================================

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      color: Colors.white,
      child: const Wrap(
        alignment: WrapAlignment.center,
        spacing: 35,
        runSpacing: 18,
        children: [
          _TrustItem(icon: Icons.bolt_rounded, label: 'Parcours simple'),
          _TrustItem(icon: Icons.phone_android, label: 'Mobile Money'),
          _TrustItem(
            icon: Icons.payments_outlined,
            label: 'Montants en Ariary',
          ),
          _TrustItem(icon: Icons.lock_outline, label: 'Clé API côté serveur'),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: darkBlue),
        ),
      ],
    );
  }
}

// ============================================================
// NOS SOLUTIONS
// ============================================================

class _ServicesSection extends StatelessWidget {
  final Key? sectionKey;

  const _ServicesSection({this.sectionKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 65),
      child: Column(
        children: [
          const Text(
            'Une expérience pensée pour vous',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Un parcours clair, du choix du montant jusqu’à la confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.6),
          ),
          const SizedBox(height: 35),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 800
                    ? 3
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 18) / columns;

                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: const _FeatureCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Paiement Mobile Money',
                        description:
                            'Choisissez un opérateur proposé par le service '
                            'et suivez les étapes de paiement.',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const _FeatureCard(
                        icon: Icons.price_check_outlined,
                        title: 'Montants en Ariary',
                        description:
                            'Saisissez un montant en Ar. Les limites sont '
                            'contrôlées à partir des informations de l’API.',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: const _FeatureCard(
                        icon: Icons.verified_user_outlined,
                        title: 'Traitement sécurisé',
                        description:
                            'La demande est envoyée au backend, qui '
                            'communique avec FiveOne Pay.',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: blue, size: 26),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: muted, height: 1.7)),
        ],
      ),
    );
  }
}

// ============================================================
// COMMENT ÇA MARCHE
// ============================================================

class _HowItWorksSection extends StatelessWidget {
  final Key? sectionKey;
  final VoidCallback onPay;
  final VoidCallback onCreateLink;

  const _HowItWorksSection({
    this.sectionKey,
    required this.onPay,
    required this.onCreateLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Comment ça marche ?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 35),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: const Wrap(
              alignment: WrapAlignment.center,
              spacing: 28,
              runSpacing: 25,
              children: [
                _StepCard(
                  number: '01',
                  title: 'Entrez le montant',
                  description: 'Indiquez le montant souhaité en Ariary.',
                ),
                _StepCard(
                  number: '02',
                  title: 'Choisissez un opérateur',
                  description: 'Sélectionnez un opérateur disponible.',
                ),
                _StepCard(
                  number: '03',
                  title: 'Finalisez le paiement',
                  description: 'Continuez sur la page de paiement hébergée.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Effectuer un paiement'),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onCreateLink,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Créer un lien de paiement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FOOTER
// ============================================================

class _Footer extends StatelessWidget {
  final VoidCallback onPay;
  final VoidCallback onCreateLink;

  const _Footer({required this.onPay, required this.onCreateLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      color: darkBlue,
      child: Column(
        children: [
          const Text(
            'FiveOne Pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Une expérience de paiement simple et claire.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFDCE7FF)),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              TextButton(
                onPressed: onPay,
                child: const Text(
                  'Accéder au paiement',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton.icon(
                onPressed: onCreateLink,
                icon: const Icon(Icons.link_rounded, color: Colors.white),
                label: const Text(
                  'Créer un lien',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Madagascar • Montants en Ariary (Ar)',
            style: TextStyle(color: Color(0xFFB9C9E8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAGE PAIEMENT CLASSIQUE ET SUIVI DU STATUT
// ============================================================

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const String backendUrl = 'http://localhost:3000';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _successUrlController = TextEditingController();
  final _cancelUrlController = TextEditingController();

  int _expiresInMinutes = 15;

  List<Map<String, dynamic>> _operators = [];
  String? _operator;
  String _message = '';
  bool _loadingOperators = true;
  bool _processingPayment = false;
  bool _checkingStatus = false;
  bool _messageIsError = false;

  Map<String, dynamic>? _lastPayment;

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _successUrlController.dispose();
    _cancelUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadOperators() async {
    try {
      final response = await http
          .get(Uri.parse('$backendUrl/api/operators'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw Exception('Réponse opérateurs invalide.');
      }

      final operators = decoded
          .whereType<Map<String, dynamic>>()
          .where((item) => item['is_active'] == true)
          .toList();

      if (!mounted) return;

      setState(() {
        _operators = operators;
        if (_operators.any((item) => item['operator'] == 'MVOLA')) {
          _operator = 'MVOLA';
        } else if (_operators.isNotEmpty) {
          _operator = _operators.first['operator'] as String?;
        }
        _loadingOperators = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingOperators = false;
        _message =
            'Impossible de charger les opérateurs. '
            'Vérifiez que le backend est démarré.';
        _messageIsError = true;
      });
    }
  }

  String _formatAriary(dynamic value) {
    final amount = value is num ? value.toInt() : 0;
    final digits = amount.toString();
    final result = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(digits[i]);
    }
    return '${result.toString()} Ar';
  }

  Map<String, dynamic>? get _selectedOperator {
    for (final item in _operators) {
      if (item['operator'] == _operator) return item;
    }
    return null;
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  bool _isOptionalHttpUrlValid(String value) {
    if (value.trim().isEmpty) return true;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  // Créer un paiement et mémoriser son identifiant.
  Future<void> _continuePayment() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = int.tryParse(
      _amountController.text.trim().replaceAll(' ', ''),
    );
    final reference = _referenceController.text.trim();
    final description = _descriptionController.text.trim();
    final payerNumber = _phoneController.text.trim();
    final successUrl = _successUrlController.text.trim();
    final cancelUrl = _cancelUrlController.text.trim();
    final selected = _selectedOperator;

    if (amount == null || amount <= 0) {
      _showMessage('Entrez un montant valide en Ariary.', isError: true);
      return;
    }

    if (reference.isEmpty) {
      _showMessage('La référence est obligatoire.', isError: true);
      return;
    }

    if (selected == null) {
      _showMessage('Choisissez un opérateur disponible.', isError: true);
      return;
    }

    final minAmount = (selected['min_amount'] as num?)?.toInt() ?? 0;
    final maxAmount = (selected['max_amount'] as num?)?.toInt() ?? 0;

    if (amount < minAmount || amount > maxAmount) {
      _showMessage(
        'Pour ${selected['label']}, le montant doit être compris entre '
        '${_formatAriary(minAmount)} et ${_formatAriary(maxAmount)}.',
        isError: true,
      );
      return;
    }

    setState(() {
      _processingPayment = true;
      _message = '';
      _messageIsError = false;
    });

    try {
      final requestBody = <String, dynamic>{
        'amount': amount,
        'reference': reference,
        'operator': _operator,
        'expiresInMinutes': _expiresInMinutes,
      };

      if (description.isNotEmpty) {
        requestBody['description'] = description;
      }
      if (payerNumber.isNotEmpty) {
        requestBody['payerNumber'] = payerNumber;
      }
      if (successUrl.isNotEmpty) {
        requestBody['successUrl'] = successUrl;
      }
      if (cancelUrl.isNotEmpty) {
        requestBody['cancelUrl'] = cancelUrl;
      }

      final response = await http
          .post(
            Uri.parse('$backendUrl/api/payments'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      final dynamic decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (response.statusCode != 201) {
        throw Exception(
          data['message'] ?? 'La demande a échoué (${response.statusCode}).',
        );
      }

      final paymentUrl = data['payment_url'];
      if (paymentUrl is! String || paymentUrl.isEmpty) {
        throw Exception('Aucune URL de paiement reçue.');
      }

      final uri = Uri.tryParse(paymentUrl);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'pay.fiveonepay.com') {
        throw Exception('URL de paiement non reconnue.');
      }

      if (!mounted) return;

      setState(() {
        _processingPayment = false;
        _lastPayment = Map<String, dynamic>.from(data);
      });

      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Paiement créé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Montant : ${_formatAriary(data['amount'])}'),
              const SizedBox(height: 8),
              Text('Référence : ${data['reference'] ?? reference}'),
              const SizedBox(height: 8),
              Text('Opérateur : ${selected['label']}'),
              const SizedBox(height: 12),
              const Text(
                'La demande est créée. Son statut doit encore être '
                'confirmé par FiveOne Pay.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Retour'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          _showMessage(
            'Impossible d’ouvrir la page de paiement.',
            isError: true,
          );
        }
      }
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _processingPayment = false);
      }
    }
  }

  // Récupérer le statut actualisé de FiveOne Pay.
  Future<void> _checkPaymentStatus() async {
    final paymentId = _lastPayment?['id'];

    if (paymentId is! String || paymentId.isEmpty) {
      _showMessage('Identifiant du paiement introuvable.', isError: true);
      return;
    }

    setState(() {
      _checkingStatus = true;
      _message = '';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              '$backendUrl/api/payments/${Uri.encodeComponent(paymentId)}',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString()
            : null;
        throw Exception(
          message ??
              'Impossible de vérifier le paiement (${response.statusCode}).',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Réponse API invalide.');
      }

      final Map<String, dynamic> paymentData = decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : Map<String, dynamic>.from(decoded);

      if (paymentData['status'] == null) {
        throw Exception('Le statut est absent de la réponse FiveOne Pay.');
      }

      final updatedPayment = Map<String, dynamic>.from(_lastPayment ?? {});
      updatedPayment.addAll(paymentData);

      if (!mounted) return;
      setState(() => _lastPayment = updatedPayment);

      _showMessage(
        'Statut actualisé : ${paymentData['status']}'.toUpperCase(),
        isError: false,
      );
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Widget _buildPaymentStatusCard() {
    final payment = _lastPayment;

    // Toujours afficher la section, même avant la création d'un paiement.
    if (payment == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E9F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: blue, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Suivi du paiement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucun paiement créé pour le moment.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Remplissez le formulaire ci-dessus et appuyez sur '
              '« Continuer vers le paiement ». Le suivi et le bouton '
              'de vérification apparaîtront ici après la création.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.refresh),
                label: const Text('Vérifier le statut'),
              ),
            ),
          ],
        ),
      );
    }

    final status = (payment['status'] ?? 'PENDING').toString().toUpperCase();

    Color statusColor = blue;
    IconData statusIcon = Icons.pending_outlined;
    String statusLabel = 'En attente de confirmation';

    if (status == 'SUCCESS') {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusLabel = 'Paiement réussi';
    } else if (status == 'EXPIRED') {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.event_busy;
      statusLabel = 'Paiement expiré';
    } else if (status == 'FAILED') {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.error_outline;
      statusLabel = 'Paiement échoué';
    } else if (status == 'PENDING') {
      statusColor = Colors.orange.shade800;
      statusIcon = Icons.hourglass_top;
      statusLabel = 'Paiement en attente';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: blue, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Suivi du paiement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatAriary(payment['amount']),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Opérateur : ${payment['operator'] ?? _operator ?? '-'}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 6),
          Text(
            'Référence : ${payment['reference'] ?? '-'}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(65)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Statut : $status',
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _checkingStatus ? null : _checkPaymentStatus,
              icon: _checkingStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                _checkingStatus
                    ? 'Vérification en cours...'
                    : 'Vérifier le statut',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Le statut affiché correspond à la dernière vérification auprès de FiveOne Pay.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour à l’accueil',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'FiveOne Pay',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Icon(Icons.shield_outlined, color: Colors.green.shade700),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Effectuer un paiement',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez votre montant, choisissez un opérateur et poursuivez sur la page de paiement.',
                    style: TextStyle(color: muted, height: 1.6),
                  ),
                  const SizedBox(height: 25),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final form = _buildPaymentForm();
                      final info = _buildInformationCard();
                      if (constraints.maxWidth >= 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: form),
                            const SizedBox(width: 22),
                            Expanded(flex: 2, child: info),
                          ],
                        );
                      }
                      return Column(
                        children: [form, const SizedBox(height: 20), info],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentStatusCard(),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'FiveOne Pay • Madagascar • Montants en Ariary (Ar)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    InputDecoration fieldDecoration({
      required String label,
      String? hint,
      Widget? prefixIcon,
      String? suffixText,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du paiement',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE0A3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined, color: Color(0xFF9A6700)),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Sandbox : le paiement est simulé.',
                      style: TextStyle(
                        color: Color(0xFF7A5100),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: fieldDecoration(
                label: 'Montant (MGA) *',
                hint: 'Ex. : 50000',
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = int.tryParse(
                  (value ?? '').trim().replaceAll(' ', ''),
                );
                if (amount == null || amount <= 0) {
                  return 'Saisissez un montant entier positif.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: fieldDecoration(
                label: 'Référence *',
                hint: 'Ex. : CMD-2026-001',
                prefixIcon: const Icon(Icons.tag),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'La référence est obligatoire.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: fieldDecoration(
                label: 'Description',
                hint: 'Optionnel',
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Opérateur de paiement *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_loadingOperators)
              const Center(child: CircularProgressIndicator())
            else if (_operators.isEmpty)
              const Text(
                'Aucun opérateur disponible. Vérifiez le backend.',
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _operator,
                isExpanded: true,
                decoration: fieldDecoration(
                  label: 'Choisissez un opérateur',
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                items: _operators.map((item) {
                  final label =
                      item['label'] as String? ?? item['operator'] as String;
                  return DropdownMenuItem<String>(
                    value: item['operator'] as String,
                    child: Text(
                      '$label (${_formatAriary(item['min_amount'])} – '
                      '${_formatAriary(item['max_amount'])})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _operator = value;
                    _message = '';
                  });
                },
                validator: (value) =>
                    value == null ? 'Choisissez un opérateur.' : null,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration(
                label: 'Téléphone du client',
                hint: 'Optionnel · ex. : 0341234567',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _expiresInMinutes,
              decoration: fieldDecoration(
                label: 'Validité du lien',
                prefixIcon: const Icon(Icons.timer_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 15,
                  child: Text('15 minutes (par défaut)'),
                ),
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 heure')),
                DropdownMenuItem(value: 180, child: Text('3 heures')),
                DropdownMenuItem(value: 360, child: Text('6 heures')),
                DropdownMenuItem(value: 720, child: Text('12 heures')),
                DropdownMenuItem(
                  value: 1440,
                  child: Text('24 heures (maximum)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _expiresInMinutes = value);
                }
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Optionnel · délai laissé au client pour payer.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _successUrlController,
              keyboardType: TextInputType.url,
              decoration: fieldDecoration(
                label: 'URL de succès',
                hint: 'Optionnel · https://exemple.mg/succes',
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
              validator: (value) {
                if (!_isOptionalHttpUrlValid(value ?? '')) {
                  return 'Entrez une URL valide commençant par http:// ou https://.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cancelUrlController,
              keyboardType: TextInputType.url,
              decoration: fieldDecoration(
                label: 'URL d’annulation',
                hint: 'Optionnel · https://exemple.mg/annulation',
                prefixIcon: const Icon(Icons.cancel_outlined),
              ),
              validator: (value) {
                if (!_isOptionalHttpUrlValid(value ?? '')) {
                  return 'Entrez une URL valide commençant par http:// ou https://.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _loadingOperators ||
                        _operators.isEmpty ||
                        _processingPayment
                    ? null
                    : _continuePayment,
                icon: _processingPayment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  _processingPayment
                      ? 'Traitement...'
                      : 'Continuer vers le paiement',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _messageIsError
                      ? const Color(0xFFFFF1F0)
                      : const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _messageIsError
                        ? const Color(0xFFB42318)
                        : const Color(0xFF16834A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 15),
            const Text(
              'Important : une demande créée ne signifie pas que le paiement '
              'est réussi. Vérifiez son statut auprès de FiveOne Pay.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: blue, size: 30),
          SizedBox(height: 15),
          Text(
            'Comment ça marche ?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          SizedBox(height: 22),
          _PaymentStep(
            number: '1',
            title: 'Montant en Ariary',
            description: 'Entrez le montant à régler en Ar.',
          ),
          SizedBox(height: 19),
          _PaymentStep(
            number: '2',
            title: 'Opérateur disponible',
            description: 'Sélectionnez un opérateur actif dans l’API.',
          ),
          SizedBox(height: 19),
          _PaymentStep(
            number: '3',
            title: 'Page de paiement',
            description: 'Continuez sur la page hébergée par FiveOne Pay.',
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _PaymentStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: ink),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF475467),
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
