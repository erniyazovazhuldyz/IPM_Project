/// Одна строка из таблицы public.profiles (см. supabase/sprint3_profiles.sql).
/// Аналог struct Profile: Codable в Swift.
final class ProfileModel {
  const ProfileModel({
    required this.id,
    this.email,
    this.fullName,
    this.city,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? city;
  final String? avatarUrl;
  final DateTime? createdAt;

  bool get hasName => fullName != null && fullName!.trim().isNotEmpty;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  /// Что показать крупно: имя, а если его нет — email.
  String get displayName => hasName ? fullName!.trim() : (email ?? '');

  /// Буквы для кружка-аватара, если фото нет: "Ayaulym Raimbek" -> "AR".
  String get initials {
    final source = hasName ? fullName!.trim() : (email ?? '').trim();
    if (source.isEmpty) return '?';
    final parts = source
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return source.characters1.toUpperCase();
    if (!hasName || parts.length == 1) {
      return parts.first.characters1.toUpperCase();
    }
    return (parts[0].characters1 + parts[1].characters1).toUpperCase();
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      city: map['city'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }

  ProfileModel copyWith({String? fullName, String? city, String? avatarUrl}) {
    return ProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}

extension on String {
  /// Первый символ (без пакета characters; для имён этого достаточно).
  String get characters1 => isEmpty ? '' : String.fromCharCode(runes.first);
}
