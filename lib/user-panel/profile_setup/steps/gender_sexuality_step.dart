import 'package:flutter/material.dart';

class GenderSexualityStep extends StatefulWidget {
  const GenderSexualityStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<GenderSexualityStep> createState() => _GenderSexualityStepState();
}

class _GenderSexualityStepState extends State<GenderSexualityStep> {
  String? _selectedGender;
  final List<String> _selectedSexuality = [];
  final List<String> _selectedRoles = [];

  final Map<String, List<String>> _roleSets = {
    'Male': ['Top', 'Bottom', 'Verse'],
    'Female': ['Butch', 'Femme', 'Futch'],
    'Trans': ['Top', 'Bottom', 'Verse', 'Switch'],
    'Other': [],
  };

  @override
  void initState() {
    super.initState();
    final rawGender = widget.initialData['gender']?.toString();
    if (rawGender != null && rawGender.isNotEmpty) {
      final normalized = rawGender[0].toUpperCase() + rawGender.substring(1).toLowerCase();
      _selectedGender = _roleSets.containsKey(normalized) ? normalized : rawGender;
    }
    
    final sexuality = widget.initialData['sexuality'];
    if (sexuality is Map) {
      _selectedSexuality.addAll(List<String>.from(sexuality['types'] ?? const []));
      _selectedRoles.addAll(List<String>.from(sexuality['roles'] ?? const []));
    } else if (sexuality is List) {
      _selectedSexuality.addAll(sexuality.map((e) => e.toString()));
    } else if (sexuality is String) {
      _selectedSexuality.addAll(sexuality.split(',').where((s) => s.isNotEmpty));
    }
    _selectedRoles.removeWhere(
      (role) => !(_roleSets[_selectedGender]?.contains(role) ?? false),
    );
  }

  void _update() {
    widget.onChanged({
      'gender': _selectedGender,
      'sexuality': {
        'types': List<String>.from(_selectedSexuality),
        'roles': List<String>.from(_selectedRoles),
      },
    });
  }

  bool get _showRoles => _selectedSexuality.contains('Homo') || _selectedSexuality.contains('Bisexual');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Gender Identity', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Select Gender'),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Trans', child: Text('Trans')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedGender = val;
                _selectedRoles.clear();
              });
              _update();
            },
          ),
          const SizedBox(height: 16),
          const Text('Sexuality Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: ['Straight', 'Homo', 'Bisexual'].map((type) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _selectedSexuality.contains(type),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedSexuality.add(type);
                        } else {
                          _selectedSexuality.remove(type);
                          if (!_showRoles) _selectedRoles.clear();
                        }
                      });
                      _update();
                    },
                  ),
                  Text(type),
                ],
              );
            }).toList(),
          ),
          if (_showRoles && _selectedGender != null && (_roleSets[_selectedGender]?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            const Text('Orientation Role', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: _roleSets[_selectedGender]!.map((role) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectedRoles.contains(role),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedRoles.add(role);
                          } else {
                            _selectedRoles.remove(role);
                          }
                        });
                        _update();
                      },
                    ),
                    Text(role),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
