import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/api/api_client.dart';

class PaymentScreen extends StatefulWidget {
  final String? initialProduct;
  const PaymentScreen({super.key, this.initialProduct});
  @override
  State<PaymentScreen> createState() => _PaymentState();
}

class _PaymentState extends State<PaymentScreen> {
  final _api = ApiClient();
  _Provider? _provider;
  String _phone = '';
  _PayStep _step = _PayStep.select;
  bool _processing = false;
  String? _paymentError;
  String _statusMessage = '';

  final _amounts = [
    _Product('Certification numérique', 500, 'Attestation officielle Diplomax',
        Icons.verified_rounded),
    _Product('Relevé officiel', 1000, 'Relevé de notes certifié MINESUP',
        Icons.description_rounded),
    _Product('Dossier complet', 2500, 'Tous vos documents certifiés',
        Icons.folder_special_rounded),
    _Product('Abonnement recruteur', 15000,
        'Accès vérification illimité / mois', Icons.business_rounded),
  ];

  _Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null && widget.initialProduct!.isNotEmpty) {
      final slug = widget.initialProduct!.toLowerCase();
      for (final product in _amounts) {
        final normalized = product.name
            .toLowerCase()
            .replaceAll(' ', '-')
            .replaceAll('é', 'e')
            .replaceAll('è', 'e')
            .replaceAll('ê', 'e');
        if (normalized.contains(slug) || slug.contains(normalized)) {
          _selectedProduct = product;
          break;
        }
      }
    }
  }

  Future<void> _pay() async {
    if (_provider == null || _phone.isEmpty || _selectedProduct == null) return;
    setState(() {
      _processing = true;
      _paymentError = null;
      _statusMessage = 'Initialisation du paiement...';
    });

    try {
      final provider = _provider == _Provider.mtn ? 'mtn' : 'orange';
      final phoneNumber = _normalizePhone(_phone);

      final initResponse = await _api.dio.post('/payments/initiate', data: {
        'provider': provider,
        'phone_number': phoneNumber,
        'amount_fcfa': _selectedProduct!.price,
        'product': _selectedProduct!.name,
      });

      final initData = initResponse.data as Map<String, dynamic>;
      final transactionId = (initData['transaction_id'] ?? '').toString();
      if (transactionId.isEmpty) {
        throw Exception('Transaction invalide retournée par le serveur');
      }

      final paid = await _pollPaymentStatus(
        transactionId: transactionId,
        provider: provider,
      );

      if (!mounted) return;
      setState(() {
        _processing = false;
        if (paid) {
          _step = _PayStep.success;
        } else {
          _paymentError =
              'Paiement en attente ou échoué. Vérifiez votre téléphone puis réessayez.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _paymentError = 'Paiement impossible: ${e.toString()}';
      });
    }
  }

  Future<bool> _pollPaymentStatus({
    required String transactionId,
    required String provider,
  }) async {
    for (int attempt = 1; attempt <= 12; attempt++) {
      if (!mounted) return false;
      setState(() {
        _statusMessage = 'Vérification du statut ($attempt/12)...';
      });

      final response = await _api.dio.get(
        '/payments/status/$transactionId',
        queryParameters: {'provider': provider},
      );

      final data = response.data as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'success' ||
          status == 'succeeded' ||
          status == 'completed' ||
          status == 'paid') {
        return true;
      }

      if (status == 'failed' || status == 'error' || status == 'cancelled') {
        return false;
      }

      await Future.delayed(const Duration(seconds: 3));
    }

    return false;
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('237')) {
      return '+$digits';
    }
    if (digits.length == 9) {
      return '+237$digits';
    }
    return '+237$digits';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/home')),
        title: Text('Paiement Mobile Money',
            style: GoogleFonts.instrumentSerif(fontSize: 22)),
      ),
      body: _step == _PayStep.success
          ? _buildSuccess()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Choisir un service'),
                  const SizedBox(height: 10),
                  ..._amounts.map(_productTile),
                  const SizedBox(height: 20),
                  _sectionTitle('Opérateur Mobile Money'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _providerCard(_Provider.mtn),
                      const SizedBox(width: 12),
                      _providerCard(_Provider.orange),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Numéro de téléphone'),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: _provider == _Provider.mtn
                          ? '6 7X XXX XXX'
                          : '6 9X XXX XXX',
                      prefixIcon: const Icon(Icons.phone_rounded,
                          color: AppColors.textHint, size: 20),
                      prefixText: '+237 ',
                      prefixStyle: GoogleFonts.dmSans(
                          fontSize: 15, color: AppColors.textPrimary),
                    ),
                    onChanged: (v) => setState(() => _phone = v),
                  ),
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 20),
                    _summaryCard(),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_provider == null ||
                            _phone.length < 9 ||
                            _selectedProduct == null ||
                            _processing)
                        ? null
                        : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _provider == _Provider.mtn
                          ? const Color(0xFFFFCC00)
                          : const Color(0xFFFF6600),
                      foregroundColor: _provider == _Provider.mtn
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: _processing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                  'Payer ${_selectedProduct != null ? "${_selectedProduct!.price} FCFA" : ""}',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15)),
                            ],
                          ),
                  ),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _statusMessage,
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  if (_paymentError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.25)),
                      ),
                      child: Text(
                        _paymentError!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Paiement sécurisé · Reçu envoyé par SMS',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary));

  Widget _productTile(_Product p) {
    final sel = _selectedProduct?.name == p.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedProduct = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(p.icon,
                  color: sel ? Colors.white : AppColors.textSecondary,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(p.description,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            Text('${p.price} FCFA',
                style: GoogleFonts.instrumentSerif(
                    fontSize: 18,
                    color: sel ? AppColors.primary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _providerCard(_Provider p) {
    final sel = _provider == p;
    final isMtn = p == _Provider.mtn;
    final color = isMtn ? const Color(0xFFFFCC00) : const Color(0xFFFF6600);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _provider = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? color.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? color : AppColors.border, width: sel ? 2 : 0.5),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    isMtn ? 'MTN' : 'OM',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: isMtn ? 11 : 13,
                        color: isMtn ? Colors.black : Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(isMtn ? 'MTN MoMo' : 'Orange Money',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _sumRow('Service', _selectedProduct!.name),
          _sumRow('Montant', '${_selectedProduct!.price} FCFA'),
          if (_phone.isNotEmpty) _sumRow('Numéro', '+237 $_phone'),
          if (_provider != null)
            _sumRow('Opérateur',
                _provider == _Provider.mtn ? 'MTN MoMo' : 'Orange Money'),
        ],
      ),
    );
  }

  Widget _sumRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(k,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            Text(v,
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: 28),
            Text('Paiement réussi !',
                style: GoogleFonts.instrumentSerif(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              'Votre certificat numérique a été ajouté à votre coffre-fort.\nUn reçu a été envoyé par SMS.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/home/vault'),
              child: const Text('Voir mes documents'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Retour à l\'accueil',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Provider { mtn, orange }

enum _PayStep { select, success }

class _Product {
  final String name;
  final int price;
  final String description;
  final IconData icon;
  const _Product(this.name, this.price, this.description, this.icon);
}
