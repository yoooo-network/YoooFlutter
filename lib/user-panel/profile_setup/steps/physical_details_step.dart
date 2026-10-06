import 'package:flutter/material.dart';

class PhysicalDetailsStep extends StatefulWidget {
  const PhysicalDetailsStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<PhysicalDetailsStep> createState() => _PhysicalDetailsStepState();
}

class _PhysicalDetailsStepState extends State<PhysicalDetailsStep> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _eyeColor;
  String? _hairType;
  String? _skinColor;
  String? _bodyStructure;
  String? _ethnicity;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.initialData['height']?.toString());
    _weightController = TextEditingController(text: widget.initialData['weight']?.toString());
    _eyeColor = widget.initialData['eye_color'];
    _hairType = widget.initialData['hair_type'];
    _skinColor = widget.initialData['skin_color'];
    _bodyStructure = widget.initialData['body_structure'];
    _ethnicity = widget.initialData['ethnicity'];
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged({
      'height': _heightController.text,
      'weight': _weightController.text,
      'eye_color': _eyeColor,
      'hair_type': _hairType,
      'skin_color': _skinColor,
      'body_structure': _bodyStructure,
      'ethnicity': _ethnicity,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildTextField('Height', 'e.g. 180 cm', _heightController),
          const SizedBox(height: 16),
          _buildTextField('Weight', 'e.g. 75 kg', _weightController),
          const SizedBox(height: 16),
          _buildDropdown('Eye Color', ['Brown', 'Black', 'Blue', 'Green', 'Hazel', 'Gray', 'Other'], _eyeColor, (val) {
            setState(() => _eyeColor = val);
            _update();
          }),
          const SizedBox(height: 16),
          _buildDropdown('Hair Type', ['Straight', 'Wavy', 'Curly', 'Coily', 'Bald', 'Other'], _hairType, (val) {
            setState(() => _hairType = val);
            _update();
          }),
          const SizedBox(height: 16),
          _buildDropdown('Skin Color', ['Fair', 'Light', 'Medium', 'Tan', 'Brown', 'Dark'], _skinColor, (val) {
            setState(() => _skinColor = val);
            _update();
          }),
          const SizedBox(height: 16),
          _buildDropdown('Body Structure', ['Slim', 'Athletic', 'Average', 'Muscular', 'Curvy', 'Plus Size'], _bodyStructure, (val) {
            setState(() => _bodyStructure = val);
            _update();
          }),
          const SizedBox(height: 16),
          _buildDropdown('Ethnicity', ['Asian', 'Black', 'Caucasian', 'Hispanic', 'Middle Eastern', 'Mixed', 'Native American', 'Other'], _ethnicity, (val) {
            setState(() => _ethnicity = val);
            _update();
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _update(),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value != null && options.contains(value)) ? value : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          hint: Text('Select $label'),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
