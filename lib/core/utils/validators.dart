class Validators {
  const Validators._();

  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final base = requiredField(value, label: 'Email');
    if (base != null) {
      return base;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final base = requiredField(value, label: 'Password');
    if (base != null) {
      return base;
    }

    if (value!.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }

    return null;
  }

  static String? price(String? value, {String label = 'Price'}) {
    final base = requiredField(value, label: label);
    if (base != null) {
      return base;
    }

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return '$label must be greater than zero.';
    }
    return null;
  }

  static String? confirmation(String? value, String expected) {
    final base = requiredField(value, label: 'Confirmation');
    if (base != null) {
      return base;
    }
    if (value != expected) {
      return 'Values do not match.';
    }
    return null;
  }
}
