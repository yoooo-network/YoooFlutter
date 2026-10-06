import 'package:flutter/material.dart';

class ContactDetailsStep extends StatefulWidget {
  const ContactDetailsStep({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  @override
  State<ContactDetailsStep> createState() => _ContactDetailsStepState();
}

class _ContactDetailsStepState extends State<ContactDetailsStep> {
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _telegramController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _discordController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialData['phone']);
    _whatsappController = TextEditingController(text: widget.initialData['whatsapp']);
    _telegramController = TextEditingController(text: widget.initialData['telegram']);
    _facebookController = TextEditingController(text: widget.initialData['facebook']);
    _instagramController = TextEditingController(text: widget.initialData['instagram']);
    _discordController = TextEditingController(text: widget.initialData['discord']);
    _websiteController = TextEditingController(text: widget.initialData['website']);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _discordController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged({
      'phone': _phoneController.text,
      'whatsapp': _whatsappController.text,
      'telegram': _telegramController.text,
      'facebook': _facebookController.text,
      'instagram': _instagramController.text,
      'discord': _discordController.text,
      'website': _websiteController.text,
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
          _buildTextField('Phone Number', 'e.g. +91 98765 43210', _phoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField('WhatsApp', 'e.g. +91 98765 43210', _whatsappController, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField('Telegram', '@username', _telegramController),
          const SizedBox(height: 16),
          _buildTextField('Facebook', 'Profile URL', _facebookController),
          const SizedBox(height: 16),
          _buildTextField('Instagram', '@username', _instagramController),
          const SizedBox(height: 16),
          _buildTextField('Discord', 'e.g. user#1234', _discordController),
          const SizedBox(height: 16),
          _buildTextField('Website', 'https://yourwebsite.com', _websiteController, keyboardType: TextInputType.url),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _update(),
        ),
      ],
    );
  }
}
