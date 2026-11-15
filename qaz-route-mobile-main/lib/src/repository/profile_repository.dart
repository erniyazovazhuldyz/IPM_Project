import 'dart:async';
import 'dart:typed_data';

import 'package:qaz_route_mobile/src/model/profile_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ошибка "пользователь не вошёл" — профиль без входа не загрузить.
class NotSignedInException implements Exception {
  const NotSignedInException();

  @override
  String toString() => 'You are not signed in';
}

/// Откуда экраны берут профиль. В тестах подставляется фейковая версия.
abstract interface class ProfileDataSource {
  /// Профиль текущего пользователя.
  Future<ProfileModel> getMyProfile();

  /// Пустая строка = стереть поле.
  Future<ProfileModel> updateProfile({
    required String fullName,
    required String city,
  });

  /// Загружает фото в Storage и сохраняет ссылку в profiles.avatar_url.
  /// [fileExtension] — "jpg", "png", ...
  Future<ProfileModel> uploadAvatar(Uint8List bytes, String fileExtension);
}

final class ProfileRepository implements ProfileDataSource {
  ProfileRepository._();

  static final ProfileRepository _instance = ProfileRepository._();

  factory ProfileRepository() => _instance;

  static const _timeout = Duration(seconds: 15);
  static const _avatarsBucket = 'avatars';

  final supabase = Supabase.instance.client;

  User get _user {
    final user = supabase.auth.currentUser;
    if (user == null) throw const NotSignedInException();
    return user;
  }

  @override
  Future<ProfileModel> getMyProfile() {
    return _guard(() async {
      final user = _user;
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_timeout);

      if (row != null) return ProfileModel.fromMap(row);

      // Строки нет (например, аккаунт создан до запуска SQL-миграции) —
      // создаём её сами. RLS разрешает вставить только свой id.
      final created = await supabase
          .from('profiles')
          .upsert({'id': user.id, 'email': user.email})
          .select()
          .single()
          .timeout(_timeout);
      return ProfileModel.fromMap(created);
    });
  }

  @override
  Future<ProfileModel> updateProfile({
    required String fullName,
    required String city,
  }) {
    return _guard(() async {
      final user = _user;
      final row = await supabase
          .from('profiles')
          .update({
            'full_name': _emptyToNull(fullName),
            'city': _emptyToNull(city),
          })
          .eq('id', user.id)
          .select()
          .single()
          .timeout(_timeout);
      return ProfileModel.fromMap(row);
    });
  }

  @override
  Future<ProfileModel> uploadAvatar(Uint8List bytes, String fileExtension) {
    return _guard(() async {
      final user = _user;
      final ext = _normalizeExtension(fileExtension);
      // Папка = id пользователя: так требует правило доступа в SQL.
      final path = '${user.id}/avatar.$ext';

      await supabase.storage
          .from(_avatarsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true, // перезаписать старое фото
              contentType: _contentType(ext),
            ),
          )
          .timeout(const Duration(seconds: 60));

      // ?v=... — чтобы приложение не показывало старую картинку из кэша.
      final publicUrl = supabase.storage.from(_avatarsBucket).getPublicUrl(path);
      final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      final row = await supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', user.id)
          .select()
          .single()
          .timeout(_timeout);
      return ProfileModel.fromMap(row);
    });
  }

  static String? _emptyToNull(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  static String _normalizeExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    return switch (e) {
      'jpeg' || 'jpg' => 'jpg',
      'png' || 'webp' || 'heic' => e,
      _ => 'jpg',
    };
  }

  static String _contentType(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'image/jpeg',
      };

  /// Сетевые ошибки -> [NoInternetException] (как в RoutesRepository).
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException {
      rethrow;
    } on StorageException {
      rethrow;
    } on NotSignedInException {
      rethrow;
    } on TimeoutException {
      throw const NoInternetException();
    } catch (e) {
      if (RoutesRepository.isNetworkError(e)) throw const NoInternetException();
      rethrow;
    }
  }
}

/// Понятный текст ошибки для экранов профиля.
String profileErrorMessage(Object error) {
  if (error is NoInternetException) {
    return 'No internet connection. Check your network and try again.';
  }
  if (error is NotSignedInException) {
    return 'Please sign in again.';
  }
  if (error is StorageException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('bucket not found')) {
      return 'Photo storage is not set up yet. '
          'Run supabase/sprint3_profiles.sql in Supabase.';
    }
    if (msg.contains('exceeded') || msg.contains('too large')) {
      return 'The photo is too large (max 5 MB).';
    }
    if (msg.contains('mime') || msg.contains('invalid_mime_type')) {
      return 'This file type is not supported. Use JPG or PNG.';
    }
    return 'Could not upload the photo: ${error.message}';
  }
  if (error is PostgrestException) {
    // 42P01 / PGRST205 = таблицы нет -> забыли запустить миграцию
    if (error.code == '42P01' ||
        error.code == 'PGRST205' ||
        error.message.contains('schema cache')) {
      return 'Profiles table is missing. '
          'Run supabase/sprint3_profiles.sql in Supabase.';
    }
    return 'Server error: ${error.message}';
  }
  return 'Something went wrong. Please try again.';
}
