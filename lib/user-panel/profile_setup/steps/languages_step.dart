import 'package:flutter/material.dart';

class LanguagesStep extends StatefulWidget {
  const LanguagesStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<LanguagesStep> createState() => _LanguagesStepState();
}

class _LanguagesStepState extends State<LanguagesStep> {
  final List<String> _selectedLanguages = [];
  late TextEditingController _otherLanguagesController;
  
  final List<String> _options = [
    'Afrikaans', 'Amharic', 'Arabic (Egyptian)', 'Arabic (Gulf)', 'Arabic (Levantine)',
    'Arabic', 'Assamese', 'Basque', 'Bengali', 'Berber (Tamazight)', 'Burmese',
    'Cantonese', 'Catalan', 'Chinese (Mandarin)', 'Danish', 'Dutch', 'English',
    'Finnish', 'French', 'German', 'Greek', 'Guarani', 'Gujarati', 'Hausa', 'Hebrew',
    'Hindi', 'Icelandic', 'Igbo', 'Indonesian', 'Irish', 'Italian', 'Japanese',
    'Javanese', 'Kannada', 'Konkani', 'Korean', 'Kurdish', 'Maithili', 'Malay',
    'Malayalam', 'Marathi', 'Nepali', 'Norwegian', 'Odia', 'Persian (Farsi)',
    'Portuguese', 'Punjabi', 'Quechua', 'Russian', 'Sanskrit', 'Scottish Gaelic',
    'Sindhi', 'Spanish', 'Swahili', 'Swedish', 'Tagalog', 'Tamil', 'Telugu', 'Thai',
    'Turkish', 'Urdu', 'Vietnamese', 'Welsh', 'Xhosa', 'Yoruba', 'Zulu'
  ];

  @override
  void initState() {
    super.initState();
    final langs = widget.initialData['languages'];
    if (langs is Map && langs['selected'] is List) {
      _selectedLanguages.addAll(List<String>.from(langs['selected']));
    }
    _otherLanguagesController = TextEditingController(
      text: (langs is Map) ? langs['others']?.toString() : '',
    );
  }

  @override
  void dispose() {
    _otherLanguagesController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged({
      'languages': {
        'selected': _selectedLanguages,
        'others': _otherLanguagesController.text,
      }
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final opt = _options[index];
              return CheckboxListTile(
                title: Text(opt, style: const TextStyle(fontSize: 14)),
                value: _selectedLanguages.contains(opt),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedLanguages.add(opt);
                    } else {
                      _selectedLanguages.remove(opt);
                    }
                  });
                  _update();
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Other Languages', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _otherLanguagesController,
            decoration: const InputDecoration(
              hintText: 'e.g. Filipino, Swahili, or any regional dialect',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _update(),
          ),
        ],
      ),
    );
  }
}
