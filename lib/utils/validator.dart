class Validator {
  /// Validasi email format
  static bool email(String email) {
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return regex.hasMatch(email);
  }

  /// Validasi password minimal 6 karakter
  static bool password(String password, {int minLength = 6}) {
    return password.length >= minLength;
  }

  /// Validasi nama tidak kosong
  static bool name(String name) {
    return name.trim().isNotEmpty;
  }
}
