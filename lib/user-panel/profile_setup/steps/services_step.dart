import 'package:flutter/material.dart';

class ServicesStep extends StatefulWidget {
  const ServicesStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  late List<String> _selectedServices;
  late TextEditingController _otherServicesController;

  @override
  void initState() {
    super.initState();
    // The API may return services as a JSON object, a legacy `selected`
    // object, or an empty value. Read only supported shapes so this step
    // always remains renderable.
    final rawServices = widget.initialData['services'];
    final servicesData = rawServices is Map
        ? Map<String, dynamic>.from(rawServices)
        : const <String, dynamic>{};
    final selected = servicesData['list'] ?? servicesData['selected'];
    _selectedServices = selected is Iterable
        ? selected.map((service) => service.toString()).toList()
        : <String>[];
    _otherServicesController = TextEditingController(
      text: servicesData['other']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _otherServicesController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged({
      'services': {
        'list': _selectedServices,
        'other': _otherServicesController.text,
      },
    });
  }

  final List<String> _options = [
    'Giving Oral Sex',
    'Receiving Oral Sex',
    'Foreplay',
    'Roleplay',
    'Cuddling',
    'All Sex Positions',
    'DFK (Deep French Kissing)',
    'A-Level (Anal Sex)',
    'Anal Rimming (Licking Anus)',
    '69 (69 Sex Position)',
    'Striptease / Lapdance',
    'Fingering / Handjob',
    'Massage',
    'GFE / BFE (Girlfriend / Boyfriend Experience)',
    'Threesome',
    'BDSM',
    'Sex Toys',
    'Extraball (Multiple Sessions)',
    'Domination',
    'LT (Long Time / Overnight)',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisExtent: 56,
              mainAxisSpacing: 8,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final opt = _options[index];
              final isSelected = _selectedServices.contains(opt);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServices.remove(opt);
                    } else {
                      _selectedServices.add(opt);
                    }
                  });
                  _update();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Colors.green.withValues(alpha: 0.05)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedServices.add(opt);
                            } else {
                              _selectedServices.remove(opt);
                            }
                          });
                          _update();
                        },
                      ),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Other Services',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherServicesController,
            decoration: const InputDecoration(
              hintText: 'e.g. Custom requests, unique experiences',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
            ),
            onChanged: (_) => _update(),
          ),
        ],
      ),
    );
  }
}
