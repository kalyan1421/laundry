// lib/core/utils/validators.dart
class Validators {
  // Phone number validation for Indian numbers
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any spaces or special characters
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length != 10) {
      return 'Phone number must be 10 digits';
    }
    
    // Check if it's a valid Indian mobile number (starts with 6-9)
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanValue)) {
      return 'Please enter a valid mobile number';
    }
    
    return null;
  }
  
  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanValue)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    String trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (trimmedValue.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid name characters (letters, spaces, dots, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s.']+$").hasMatch(trimmedValue)) {
      return 'Name can only contain letters, spaces, dots and apostrophes';
    }
    
    return null;
  }
  
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    String trimmedValue = value.trim().toLowerCase();
    
    // Basic email regex pattern
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Static method to check if email is valid (returns boolean)
  static bool isValidEmail(String email) {
    String trimmedValue = email.trim().toLowerCase();
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmedValue);
  }
  
  // Address validation
  static String? validateAddress(String? value, {String fieldName = 'Address'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    String trimmedValue = value.trim();
    
    if (trimmedValue.length < 5) {
      return '$fieldName must be at least 5 characters';
    }
    
    if (trimmedValue.length > 100) {
      return '$fieldName must be less than 100 characters';
    }
    
    return null;
  }
  
  // Pincode validation for India
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length != 6) {
      return 'Pincode must be 6 digits';
    }
    
    // Indian pincode validation (starts with 1-9)
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(cleanValue)) {
      return 'Please enter a valid pincode';
    }
    
    return null;
  }
  
  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }
    
    String trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'City name must be at least 2 characters';
    }
    
    if (trimmedValue.length > 30) {
      return 'City name must be less than 30 characters';
    }
    
    // Check for valid city name characters
    if (!RegExp(r"^[a-zA-Z\s.']+$").hasMatch(trimmedValue)) {
      return 'City name can only contain letters, spaces, dots and apostrophes';
    }
    
    return null;
  }
  
  // State validation
  static String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'State is required';
    }
    
    String trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'State name must be at least 2 characters';
    }
    
    if (trimmedValue.length > 30) {
      return 'State name must be less than 30 characters';
    }
    
    return null;
  }
  
  // Generic validator for non-empty fields
  static String? validateGeneric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return '$fieldName can be at most 100 characters';
    }
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (value.length > 20) {
      return 'Password must be less than 20 characters';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Generic required field validation
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Numeric validation
  static String? validateNumeric(String? value, {String fieldName = 'Field', double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    double? numValue = double.tryParse(value);
    if (numValue == null) {
      return '$fieldName must be a valid number';
    }
    
    if (min != null && numValue < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && numValue > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }
  
  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    int? age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }
  
  // URL validation
  static String? validateURL(String? value, {String fieldName = 'URL'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    String trimmedValue = value.trim();
    
    try {
      Uri uri = Uri.parse(trimmedValue);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        return 'Please enter a valid URL';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
  
  // Indian vehicle number validation
  static String? validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\w]'), '').toUpperCase();
    
    // Indian vehicle number pattern: XX00XX0000
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$').hasMatch(cleanValue)) {
      return 'Please enter a valid vehicle number (e.g., KA01AB1234)';
    }
    
    return null;
  }
  
  // Aadhar number validation
  static String? validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length != 12) {
      return 'Aadhar number must be 12 digits';
    }
    
    if (!RegExp(r'^[2-9][0-9]{11}$').hasMatch(cleanValue)) {
      return 'Please enter a valid Aadhar number';
    }
    
    return null;
  }
  
  // Pan card validation
  static String? validatePAN(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\w]'), '').toUpperCase();
    
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(cleanValue)) {
      return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
    }
    
    return null;
  }
  
  // Bank account number validation
  static String? validateBankAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bank account number is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length < 9 || cleanValue.length > 18) {
      return 'Bank account number must be between 9-18 digits';
    }
    
    return null;
  }
  
  // IFSC code validation
  static String? validateIFSC(String? value) {
    if (value == null || value.isEmpty) {
      return 'IFSC code is required';
    }
    
    String cleanValue = value.replaceAll(RegExp(r'[^\w]'), '').toUpperCase();
    
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleanValue)) {
      return 'Please enter a valid IFSC code (e.g., SBIN0001234)';
    }
    
    return null;
  }
  
  // Helper method to format phone number
  static String formatPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return phoneNumber;
  }
  
  // Helper method to clean phone number
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }
}