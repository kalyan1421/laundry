// widgets/mobile/mobile_contact_section.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class MobileContactSection extends StatefulWidget {
  const MobileContactSection({Key? key}) : super(key: key);

  @override
  State<MobileContactSection> createState() => _MobileContactSectionState();
}

class _MobileContactSectionState extends State<MobileContactSection> {
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
            // Header with background image
            Image.asset(
              'assets/images/contact_bg.png',
              fit: BoxFit.cover,
              height: 120,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                );
              },
            ),
            
            // Main Content
            Container(
              color: AppTheme.lightBackground,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Info Section
                  _buildContactInfo(context),
                  const SizedBox(height: 40),
                  
                  // Contact Form Section
                  _buildContactForm(context),
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
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 24),
        
        // Map placeholder
        Center(
          child: Container(
            width: 180,
            height: 100,
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
                      size: 30,
                      color: AppTheme.primaryBlue,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Contact Items
        _buildClickableContactItem(Icons.phone, '9566654788', () => _makePhoneCall('9566654788')),
        const SizedBox(height: 16),
        _buildClickableContactItem(Icons.phone, '6382654316', () => _makePhoneCall('6382654316')),
        const SizedBox(height: 16),
        _buildClickableContactItem(Icons.email, 'cloudironingfactory@gmail.com', () => _sendEmail('cloudironingfactory@gmail.com')),
        const SizedBox(height: 16),
        
        // Website
        _buildClickableContactItem(Icons.language, 'www.cloudironingfactory.com', () => _openWebsite('https://cloudironingfactory.com')),
        const SizedBox(height: 16),
        
        // Book a Pickup Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _bookPickup(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: Icon(Icons.calendar_today, size: 18),
            label: Text(
              'Book a Pickup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.primaryFont,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Addresses
        _buildContactItem(
          Icons.location_on,
          'Registered Address: Tulip A5, Majestic Orchid, Ben Foundation, Jaswanth Nagar, Mogappair West, Chennai - 600037.',
        ),
        const SizedBox(height: 12),
        
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
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
              size: 10,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Email Field
            _buildTextField(
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
              maxLines: 5,
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
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _sendMessage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                icon: Icon(Icons.send, size: 18),
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
}