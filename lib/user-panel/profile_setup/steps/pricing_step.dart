import 'package:flutter/material.dart';

class PricingStep extends StatefulWidget {
  const PricingStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  late String _selectedCurrency;
  late Map<String, String> _prices;

  @override
  void initState() {
    super.initState();
    // Profile responses can contain legacy flat prices, numeric JSON values,
    // or an empty/null pricing value. Do not let any of those prevent this
    // step from building.
    final rawPricing = widget.initialData['pricing'];
    final pricing = rawPricing is Map
        ? Map<String, dynamic>.from(rawPricing)
        : const <String, dynamic>{};
    final rawCurrency = pricing['currency']?.toString().toUpperCase();
    _selectedCurrency = _currencies.containsKey(rawCurrency)
        ? rawCurrency!
        : 'INR';

    final rawRates = pricing['rates'];
    _prices = rawRates is Map
        ? rawRates.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          )
        : <String, String>{};

    for (final key in _prices.keys.toList()) {
      final raw = _prices[key]?.trim() ?? '';
      final currencyMatch = RegExp(r'([A-Za-z]{3})$').firstMatch(raw);
      if (currencyMatch != null) {
        final currency = currencyMatch.group(1)!.toUpperCase();
        if (_currencies.containsKey(currency)) {
          _selectedCurrency = currency;
        }
      }

      final numberMatch = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(raw);
      if (numberMatch != null) {
        _prices[key] = numberMatch.group(1)!;
      } else {
        _prices[key] = raw.replaceAll(RegExp(r'[A-Za-z]'), '');
      }
    }
  }

  void _update() {
    widget.onChanged({
      'pricing': {'currency': _selectedCurrency, 'rates': _prices},
    });
  }

  final Map<String, String> _currencies = {
    'ARS': 'Argentine Peso (ARS)',
    'AUD': 'Australian Dollar (AUD)',
    'EUR': 'Euro (EUR)',
    'BDT': 'Bangladeshi Taka (BDT)',
    'BRL': 'Brazilian Real (BRL)',
    'CAD': 'Canadian Dollar (CAD)',
    'COP': 'Colombian Peso (COP)',
    'CDF': 'Congolese Franc (CDF)',
    'EGP': 'Egyptian Pound (EGP)',
    'GHS': 'Ghanaian Cedi (GHS)',
    'ISK': 'Icelandic Króna (ISK)',
    'INR': 'Indian Rupee (INR)',
    'IDR': 'Indonesian Rupiah (IDR)',
    'IRR': 'Iranian Rial (IRR)',
    'ILS': 'Israeli New Shekel (ILS)',
    'JPY': 'Japanese Yen (JPY)',
    'MYR': 'Malaysian Ringgit (MYR)',
    'MXN': 'Mexican Peso (MXN)',
    'MAD': 'Moroccan Dirham (MAD)',
    'NZD': 'New Zealand Dollar (NZD)',
    'NGN': 'Nigerian Naira (NGN)',
    'NOK': 'Norwegian Krone (NOK)',
    'OMR': 'Omani Rial (OMR)',
    'QAR': 'Qatari Riyal (QAR)',
    'SAR': 'Saudi Riyal (SAR)',
    'SGD': 'Singapore Dollar (SGD)',
    'ZAR': 'South African Rand (ZAR)',
    'KRW': 'South Korean Won (KRW)',
    'TWD': 'New Taiwan Dollar (TWD)',
    'THB': 'Thai Baht (THB)',
    'TRY': 'Turkish Lira (TRY)',
    'AED': 'United Arab Emirates Dirham (AED)',
    'GBP': 'British Pound (GBP)',
    'USD': 'United States Dollar (USD)',
    'VES': 'Venezuelan Bolívar (VES)',
    'VND': 'Vietnamese Đồng (VND)',
  };

  final List<Map<String, String>> _durations = [
    {'label': '1 Hour', 'key': '1hr'},
    {'label': '3 Hours', 'key': '3hr'},
    {'label': 'Full Night', 'key': 'night'},
    {'label': 'Full Week', 'key': 'week'},
    {'label': 'Full Month', 'key': 'month'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Currency',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _currencies.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCurrency = val!;
              });
              _update();
            },
          ),
          const SizedBox(height: 24),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Duration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ..._durations.map((d) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(d['label']!, textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: TextFormField(
                        initialValue: _prices[d['key']],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          _prices[d['key']!] = val;
                          _update();
                        },
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
