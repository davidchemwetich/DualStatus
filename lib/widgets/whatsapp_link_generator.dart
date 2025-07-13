import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class WhatsAppLinkGenerator extends StatefulWidget {
  const WhatsAppLinkGenerator({Key? key}) : super(key: key);

  @override
  State<WhatsAppLinkGenerator> createState() => _WhatsAppLinkGeneratorState();
}

class _WhatsAppLinkGeneratorState extends State<WhatsAppLinkGenerator> {
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String _generatedLink = '';
  String _completePhoneNumber = '';
  bool _isLoading = false;
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _generateLink() {
    if (!_formKey.currentState!.validate() || !_isPhoneValid) {
      _showSnackBar('Please enter a valid phone number', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Clean and prepare phone number
    String phoneNumber = _completePhoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Encode the message
    String encodedMessage = Uri.encodeComponent(_messageController.text);

    // Generate the WhatsApp link
    String link = 'https://wa.me/$phoneNumber';
    if (_messageController.text.isNotEmpty) {
      link += '?text=$encodedMessage';
    }

    setState(() {
      _generatedLink = link;
      _isLoading = false;
    });

    _showSnackBar('Link generated successfully!', Colors.green);
  }

  void _copyToClipboard() {
    if (_generatedLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedLink));
      _showSnackBar('Link copied to clipboard!', Colors.green);
    }
  }

  void _openWhatsApp() async {
    if (_generatedLink.isNotEmpty) {
      final Uri url = Uri.parse(_generatedLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open WhatsApp', Colors.red);
      }
    }
  }

  void _openWhatsAppBusiness() async {
    if (_generatedLink.isNotEmpty) {
      // Convert regular WhatsApp link to WhatsApp Business
      String businessLink = _generatedLink.replaceAll('wa.me', 'api.whatsapp.com/send');
      final Uri url = Uri.parse(businessLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open WhatsApp Business', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearFields() {
    setState(() {
      _messageController.clear();
      _generatedLink = '';
      _completePhoneNumber = '';
      _isPhoneValid = false;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'WhatsApp Link Generator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All',
            onPressed: _clearFields,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'How to use',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Select your country and enter phone number\n'
                        '2. Add your custom message (optional)\n'
                        '3. Generate the link and copy or open directly\n'
                        '4. Share with WhatsApp or WhatsApp Business',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number Input with Country Code
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF075E54).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Color(0xFF075E54),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF075E54),
                              width: 2,
                            ),
                          ),
                        ),
                        initialCountryCode: 'US',
                        onChanged: (phone) {
                          setState(() {
                            _completePhoneNumber = phone.completeNumber;
                            _isPhoneValid = phone.number.isNotEmpty;
                          });
                        },
                        onCountryChanged: (country) {
                          setState(() {
                            _isPhoneValid = false;
                            _completePhoneNumber = '';
                          });
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          if (!phone.isValidNumber()) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_completePhoneNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Complete number: $_completePhoneNumber',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Message Input
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.message,
                              color: Colors.orange[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Custom Message (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF075E54),
                              width: 2,
                            ),
                          ),
                          hintText: 'Enter your custom message here...',
                          helperText: 'This message will be pre-filled when the link is opened',
                          helperMaxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Quick message templates
                      const Text(
                        'Quick Templates:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildQuickTemplate('Hello! 👋'),
                          _buildQuickTemplate('How can I help you?'),
                          _buildQuickTemplate('Contact me for more info'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Generate WhatsApp Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Generated Link Display
              if (_generatedLink.isNotEmpty) ...[
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.link,
                                color: Colors.green[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Generated Link',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your WhatsApp Link:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _generatedLink,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            // Copy Link Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('Copy Link to Clipboard'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _openWhatsApp,
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('WhatsApp'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _openWhatsAppBusiness,
                                      icon: const Icon(Icons.business, size: 18),
                                      label: const Text('Business'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF075E54),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildQuickTemplate(String template) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _messageController.text = template;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF075E54).withOpacity(0.3)),
        ),
        child: Text(
          template,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF075E54),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}