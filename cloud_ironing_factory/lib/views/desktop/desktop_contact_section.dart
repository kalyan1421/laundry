// widgets/desktop/desktop_contact_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class DesktopContactSection extends StatefulWidget {
  const DesktopContactSection({Key? key}) : super(key: key);

  @override
  State<DesktopContactSection> createState() => _DesktopContactSectionState();
}

class _DesktopContactSectionState extends State<DesktopContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Phone Call Functionality
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorMessage('Could not open phone dialer');
      }
    } catch (e) {
      _showErrorMessage('Error making phone call: $e');
    }
  }

  // Email Functionality
  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry about Cloud Ironing Factory Services',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorMessage('Could not open email client');
      }
    } catch (e) {
      _showErrorMessage('Error opening email: $e');
    }
  }

  // Website Functionality
  Future<void> _openWebsite(String url) async {
    final Uri websiteUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorMessage('Could not open website');
      }
    } catch (e) {
      _showErrorMessage('Error opening website: $e');
    }
  }

  // Book Pickup Functionality
  Future<void> _bookPickup() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/919566654788?text=Hi! I would like to book a pickup for ironing services. Please let me know the available slots.',
    );
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to phone call
        _makePhoneCall('9566654788');
      }
    } catch (e) {
      _showErrorMessage('Error booking pickup: $e');
    }
  }

  // Enhanced Message Sending
  Future<void> _sendMessage() async {
    String name = _nameController.text;
    String email = _emailController.text;
    String subject = _subjectController.text;
    String message = _messageController.text;

    String emailBody = '''
Hello Cloud Ironing Factory,

Name: $name
Email: $email
Subject: $subject

Message:
$message

Best regards,
$name
    ''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'cloudironingfactory@gmail.com',
      query: 'subject=$subject&body=${Uri.encodeComponent(emailBody)}',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _showSuccessMessage('Email client opened successfully!');
        _clearForm();
      } else {
        _showErrorMessage('Could not open email client');
      }
    } catch (e) {
      _showErrorMessage('Error sending message: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryBlue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Contact Section
        _buildContactSection(context),
        // Footer Section
        // _buildFooterSection(context),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/contact_bg.png'),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.85),
        ),
        child: Column(
          children: [
            // Header with background image and title
            Image.asset('assets/images/contact_bg.png', fit: BoxFit.cover,  ),
           
            
            // Main Content
            Container(
              color: AppTheme.lightBackground,
              padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 80.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left - Contact Info
                  Expanded(
                    flex: 5,
                    child: _buildContactInfo(context),
                  ),
                  const SizedBox(width: 80),
                  
                  // Right - Contact Form
                  Expanded(
                    flex: 7,
                    child: _buildContactForm(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lets Talk With Us..',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.primaryFont,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 40),
        
        // Map placeholder
        Container(
          width: 300,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue, width: 2),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/map_location.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.map,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Phone
        _buildClickableContactItem(Icons.phone, '9566654788', () => _makePhoneCall('9566654788')),
        const SizedBox(height: 24),
        _buildClickableContactItem(Icons.phone, '6382654316', () => _makePhoneCall('6382654316')),
        const SizedBox(height: 24),
        // Email
        _buildClickableContactItem(Icons.email, 'cloudironingfactory@gmail.com', () => _sendEmail('cloudironingfactory@gmail.com')),
        const SizedBox(height: 24),
        
        // Website
        _buildClickableContactItem(Icons.language, 'www.cloudironingfactory.com', () => _openWebsite('https://cloudironingfactory.com')),
        const SizedBox(height: 24),
        
        // Book a Pickup Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _bookPickup(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: Icon(Icons.calendar_today, size: 20),
            label: Text(
              'Book a Pickup',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFont,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Registered Address
        _buildContactItem(
          Icons.location_on,
          'Registered Address: Tulip A5, Majestic Orchid, Ben Foundation, Jaswanth Nagar, Mogappair West, Chennai - 600037.',
        ),
        const SizedBox(height: 16),
        
        // Administrative Office Address
        _buildContactItem(
          Icons.business,
          'Administrative Office Address: B-10, Mogappair West Industrial Estate, Reddypalayam Road, 3rd Street Mogappair West Estate, Chennai - 600037',
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                height: 1.5,
                fontFamily: AppTheme.primaryFont,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClickableContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: AppTheme.primaryFont,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Name Field
                Expanded(
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Email Field
                Expanded(
                  child: _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Subject Field
            _buildTextField(
              controller: _subjectController,
              label: 'Subject',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Message Field
            _buildTextField(
              controller: _messageController,
              label: 'Message',
              maxLines: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _sendMessage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                icon: Icon(Icons.send, size: 20),
                label: Text(
                  'Send',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.primaryFont,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: AppTheme.textDark,
        fontFamily: AppTheme.primaryFont,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontFamily: AppTheme.primaryFont,
        ),
        filled: true,
        fillColor: AppTheme.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkBlue,
      padding: const EdgeInsets.all(40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left - Logo and Company Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Icon(
                              Icons.iron,
                              size: 60,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cloud Ironing\nFactory',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Center - Company Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLOUD IRONING FACTORY PRIVATE LIMITED',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Navigation Links
                  _buildFooterLink('Home'),
                  _buildFooterLink('About'),
                  _buildFooterLink('Services'),
                  _buildFooterLink('Contact Us'),
                  
                  const SizedBox(height: 20),
                  
                  // Contact Info
                  _buildFooterContactItem(Icons.phone, '+91 9566654788'),
                  // _buildFooterContactItem(Icons.whatsapp, '+91 9566677166'),
                  _buildFooterContactItem(Icons.phone, '+91 6382654316'),
                  _buildFooterContactItem(Icons.email, 'cloudironingfactory@gmail.com'),
                  
                  const SizedBox(height: 16),
                  
                  // Addresses
                  _buildFooterContactItem(Icons.location_on, 'Registered Address: Tulip A5, Majestic Orchid, Ben Foundation, Jaswanth Nagar, Mogappair West, Chennai - 600037.'),
                  const SizedBox(height: 8),
                  _buildFooterContactItem(Icons.business, 'Administrative Office Address: B-10, Mogappair West Industrial Estate, Reddypalayam Road, 3rd Street Mogappair West Estate, Chennai - 600037'),
                ],
              ),
            ),
            
            // Right - QR Code and Download App
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Download App',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTheme.primaryFont,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // QR Code
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/qr_code.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.qr_code,
                              size: 60,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.white,
          fontSize: 14,
          fontFamily: AppTheme.primaryFont,
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.white,
        ),
      ),
    );
  }

  Widget _buildFooterContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 12,
                fontFamily: AppTheme.primaryFont,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}