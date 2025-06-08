// utils/validators.dart
class Validators {
  // Validate if field is not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Validate phone number (Indian format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters for validation
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    // Check if it starts with valid Indian mobile number prefixes
    if (!cleanNumber.startsWith(RegExp(r'^[6-9]'))) {
      return 'Please enter a valid Indian mobile number';
    }
    
    return null;
  }

  // Validate name (only alphabets and spaces)
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    // Check if name contains only alphabets and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Validate license number
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    
    if (value.trim().length < 6) {
      return 'License number must be at least 6 characters long';
    }
    
    // Check for valid license format (alphanumeric)
    final licenseRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!licenseRegex.hasMatch(value.trim())) {
      return 'License number can only contain letters and numbers';
    }
    
    return null;
  }

  // Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    // Check if all characters are digits
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    
    return null;
  }

  // Validate age (for delivery partners)
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    
    int? age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 18) {
      return 'Must be at least 18 years old';
    }
    
    if (age > 65) {
      return 'Age cannot be more than 65 years';
    }
    
    return null;
  }

  // Validate required field with minimum length
  static String? validateRequiredWithMinLength(String? value, String fieldName, int minLength) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  // Validate numeric input
  static String? validateNumeric(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    int? number = int.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid number for $fieldName';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName cannot be more than $max';
    }
    
    return null;
  }

  // Validate URL format
  static String? validateURL(String? value, {bool required = false}) {
    if (!required && (value == null || value.trim().isEmpty)) {
      return null;
    }
    
    if (required && (value == null || value.trim().isEmpty)) {
      return 'URL is required';
    }
    
    final urlRegex = RegExp(r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    if (!urlRegex.hasMatch(value!.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
}