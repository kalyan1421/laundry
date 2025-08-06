class PhoneFormatter {
  /// Formats phone number by removing +91 prefix
  /// Returns the phone number without +91 prefix
  static String formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return 'N/A';
    }
    
    // Remove +91 prefix if present
    String formatted = phoneNumber.trim();
    if (formatted.startsWith('+91')) {
      formatted = formatted.substring(3);
    } else if (formatted.startsWith('91') && formatted.length > 10) {
      formatted = formatted.substring(2);
    }
    
    // Remove any leading zeros
    formatted = formatted.replaceFirst(RegExp(r'^0+'), '');
    
    return formatted.trim();
  }
  
  /// Gets client ID (phone number without +91)
  static String getClientId(String? phoneNumber) {
    return formatPhoneNumber(phoneNumber);
  }
} 