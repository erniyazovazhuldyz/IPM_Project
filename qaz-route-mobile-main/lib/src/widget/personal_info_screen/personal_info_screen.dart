import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/core/validators.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/profile_repository.dart';
import 'package:qaz_route_mobile/src/widget/common/profile_avatar.dart';
import 'package:qaz_route_mobile/src/widget/personal_info_screen/personal_info_controller.dart';

/// Экран редактирования профиля: фото, имя, город, смена пароля.
/// Открывается из Profile -> "Personal information".
@RoutePage()
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  var _passwordFormKey = GlobalKey<FormState>();

  late final PersonalInfoController _controller;
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = PersonalInfoController(
      profileRepository: ProfileRepository(),
      authRepository: AuthRepository(),
    );
    _load();
  }

  /// Загружаем профиль и один раз заполняем поля ввода.
  Future<void> _load() async {
    await _controller.load();
    final profile = _controller.profile;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _cityController.text = profile.city ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _showResult(String? error, {required String success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? success),
          backgroundColor:
              error == null ? AppColors.lightGreen700 : AppColors.supplementary600900,
        ),
      );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;

    final error = await _controller.save(
      fullName: _nameController.text,
      city: _cityController.text,
    );
    _showResult(error, success: 'Profile saved');
  }

  Future<void> _pickAvatar() async {
    try {
      // Картинка сразу уменьшается: так загрузка быстрее и меньше места в Storage.
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return; // пользователь закрыл галерею

      final bytes = await file.readAsBytes();
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';

      final error = await _controller.uploadAvatar(bytes, ext);
      _showResult(error, success: 'Photo updated');
    } catch (e) {
      _showResult(
        'Could not open the gallery. Check photo access in Settings.',
        success: '',
      );
    }
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    final error = await _controller.changePassword(_newPasswordController.text);
    if (error == null) {
      _newPasswordController.clear();
      _repeatPasswordController.clear();
      // новый ключ формы убирает подсказки "Enter your password" под пустыми полями
      setState(() => _passwordFormKey = GlobalKey<FormState>());
    }
    _showResult(error, success: 'Password changed');
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.neutral500),
      floatingLabelStyle: const TextStyle(color: AppColors.lightGreen700),
      prefixIcon: Icon(icon, color: AppColors.black),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.black),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.black, width: 1.5),
      ),
    );
  }

  ButtonStyle get _primaryButtonStyle => ElevatedButton.styleFrom(
        minimumSize: const Size(double.maxFinite, 48),
        backgroundColor: AppColors.lightGreen600,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.lightGreen200,
        disabledForegroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      );

  Widget _buttonChild(String text, bool loading) => loading
      ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.white,
            strokeWidth: 2,
          ),
        )
      : Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        foregroundColor: AppColors.white,
        title: const Text(
          'Personal information',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            switch (_controller.state) {
              case PersonalInfoState.loading:
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.lightGreen600,
                  ),
                );
              case PersonalInfoState.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.errorMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightGreen600,
                            foregroundColor: AppColors.white,
                          ),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                );
              case PersonalInfoState.idle:
                return _buildForm();
            }
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    final profile = _controller.profile!;
    final busy = _controller.isBusy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      children: [
        // ---------- Фото ----------
        Center(
          child: Stack(
            children: [
              ProfileAvatar(profile: profile, radius: 56),
              if (_controller.isUploadingAvatar)
                const Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: Color(0x88000000),
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: AppColors.lightGreen600,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.white, width: 2),
                  ),
                  child: IconButton(
                    key: const ValueKey('personal_info_change_photo'),
                    tooltip: 'Change photo',
                    icon: const Icon(
                      Icons.photo_camera,
                      color: AppColors.white,
                      size: 20,
                    ),
                    onPressed: busy ? null : _pickAvatar,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: busy ? null : _pickAvatar,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lightGreen700,
            ),
            child: const Text('Change photo'),
          ),
        ),
        const SizedBox(height: 16),

        // ---------- Имя, город ----------
        Form(
          key: _profileFormKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: profile.email ?? '',
                enabled: false,
                decoration: _decoration('Email', Icons.email),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('personal_info_name'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: Validators.optionalText(),
                cursorColor: AppColors.supplementary600,
                decoration: _decoration('Name', Icons.person),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('personal_info_city'),
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: Validators.optionalText(),
                cursorColor: AppColors.supplementary600,
                decoration: _decoration('City', Icons.location_city),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const ValueKey('personal_info_save'),
                onPressed: busy ? null : _save,
                style: _primaryButtonStyle,
                child: _buttonChild('Save', _controller.isSaving),
              ),
            ],
          ),
        ),

        // ---------- Смена пароля ----------
        const SizedBox(height: 40),
        const Text(
          'CHANGE PASSWORD',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Form(
          key: _passwordFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: Validators.password,
                cursorColor: AppColors.supplementary600,
                decoration: _decoration(
                  'New password',
                  Icons.lock,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.black,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repeatPasswordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _changePassword(),
                validator: Validators.confirmPassword(
                  () => _newPasswordController.text,
                ),
                cursorColor: AppColors.supplementary600,
                decoration: _decoration('Repeat new password', Icons.lock_outline),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: busy ? null : _changePassword,
                style: _primaryButtonStyle,
                child: _buttonChild(
                  'Update password',
                  _controller.isChangingPassword,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
