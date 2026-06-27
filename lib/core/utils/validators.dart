class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^03\d{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid Pakistan phone (03XXXXXXXXX)';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = double.tryParse(value);
    if (amount == null || amount < 0) return 'Enter a valid amount';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Value']) {
    if (value == null || value.isEmpty) return '$field is required';
    final num = double.tryParse(value);
    if (num == null || num <= 0) return '$field must be greater than 0';
    return null;
  }

  static String? cnic(String? value) {
    if (value == null || value.isEmpty) return null;
    final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d{1}$');
    if (!cnicRegex.hasMatch(value)) return 'Enter CNIC format: XXXXX-XXXXXXX-X';
    return null;
  }
}
