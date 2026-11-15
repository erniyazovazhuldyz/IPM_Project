import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/profile_model.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/profile_repository.dart';

enum PersonalInfoState { loading, idle, error }

/// ViewModel экрана "Personal information".
/// Методы save / uploadAvatar / changePassword возвращают текст ошибки
/// или null, если всё прошло хорошо — экран показывает результат в SnackBar.
class PersonalInfoController extends ChangeNotifier {
  PersonalInfoController({
    required this.profileRepository,
    required this.authRepository,
  });

  final ProfileDataSource profileRepository;
  final AuthRepository authRepository;

  PersonalInfoState _state = PersonalInfoState.loading;

  PersonalInfoState get state => _state;

  ProfileModel? _profile;

  ProfileModel? get profile => _profile;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  bool _isSaving = false;

  bool get isSaving => _isSaving;

  bool _isUploadingAvatar = false;

  bool get isUploadingAvatar => _isUploadingAvatar;

  bool _isChangingPassword = false;

  bool get isChangingPassword => _isChangingPassword;

  /// Идёт ли какая-нибудь операция (тогда кнопки блокируются).
  bool get isBusy => _isSaving || _isUploadingAvatar || _isChangingPassword;

  Future<void> load() async {
    _state = PersonalInfoState.loading;
    notifyListeners();
    try {
      _profile = await profileRepository.getMyProfile();
      _state = PersonalInfoState.idle;
    } catch (e) {
      _state = PersonalInfoState.error;
      _errorMessage = profileErrorMessage(e);
    }
    notifyListeners();
  }

  Future<String?> save({
    required String fullName,
    required String city,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      _profile = await profileRepository.updateProfile(
        fullName: fullName,
        city: city,
      );
      return null;
    } catch (e) {
      return profileErrorMessage(e);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> uploadAvatar(Uint8List bytes, String fileExtension) async {
    _isUploadingAvatar = true;
    notifyListeners();
    try {
      _profile = await profileRepository.uploadAvatar(bytes, fileExtension);
      return null;
    } catch (e) {
      return profileErrorMessage(e);
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String newPassword) async {
    _isChangingPassword = true;
    notifyListeners();
    try {
      await authRepository.changePassword(newPassword);
      return null;
    } catch (e) {
      return authErrorMessage(e);
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }
}
