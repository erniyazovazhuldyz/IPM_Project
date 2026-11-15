/// Проверки полей ввода для TextFormField(validator: ...).
/// Возвращают текст ошибки или null, если всё хорошо.
abstract final class Validators {
  static final _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Минимум, который требует Supabase по умолчанию.
  static const minPasswordLength = 6;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegExp.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (v.length < minPasswordLength) {
      return 'At least $minPasswordLength characters';
    }
    return null;
  }

  /// Для поля "повторите пароль".
  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      final error = password(value);
      if (error != null) return error;
      if (value != original()) return 'Passwords do not match';
      return null;
    };
  }

  /// Необязательное поле, но не длиннее [max] символов.
  static String? Function(String?) optionalText({int max = 60}) {
    return (value) {
      if ((value?.trim().length ?? 0) > max) {
        return 'Maximum $max characters';
      }
      return null;
    };
  }
}
