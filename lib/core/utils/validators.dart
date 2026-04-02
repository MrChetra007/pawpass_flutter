class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? petName(String? value) {
    final result = required(value, fieldName: 'Pet name');
    if (result != null) return result;
    if (value!.length > 50) {
      return 'Pet name must be less than 50 characters';
    }
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.isEmpty) return null;
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }
    if (weight <= 0 || weight > 500) {
      return 'Please enter a valid weight';
    }
    return null;
  }

  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    return null;
  }
}
