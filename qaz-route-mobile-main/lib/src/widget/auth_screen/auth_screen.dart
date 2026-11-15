import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/core/validators.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/auth_screen/auth_screen_controller.dart';

/// Экран входа / регистрации.
/// Открывается с вкладки Profile (context.router.push(const AuthRoute())).
/// После успешного входа экран закрывается и пользователь возвращается назад.
@RoutePage()
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final AuthScreenController _authScreenController;
  bool _isPasswordVisible = false;
  bool _isSignIn = true;

  @override
  void initState() {
    super.initState();
    _authScreenController = AuthScreenController(repository: AuthRepository());
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _authScreenController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Закрыть экран после входа. Если закрывать некуда (экран открыли по
  /// прямой ссылке /auth) — переходим в основное приложение.
  Future<void> _closeAfterSuccess() async {
    final router = context.router;
    final popped = await router.maybePop(true);
    if (!popped) {
      await router.replace(const AppRoute());
    }
  }

  Future<void> _submit() async {
    if (_authScreenController.isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bool isSuccess;
    if (_isSignIn) {
      isSuccess = await _authScreenController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      isSuccess = await _authScreenController.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
      );
      // Нужно подтвердить почту -> переключаем на "Sign In",
      // чтобы после подтверждения сразу можно было войти.
      if (!isSuccess &&
          mounted &&
          _authScreenController.infoMessage.isNotEmpty) {
        setState(() {
          _isSignIn = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    }

    if (isSuccess && mounted) {
      await _closeAfterSuccess();
    }
  }

  void _toggleMode() {
    _authScreenController.clearMessages();
    setState(() {
      _isSignIn = !_isSignIn;
      // Новый ключ формы = старые красные подсказки под полями исчезают,
      // а введённый email остаётся.
      _formKey = GlobalKey<FormState>();
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(
        initialEmail: _emailController.text,
        decoration: _getInputDecoration(
          hintText: 'Email',
          prefixIcon: Icons.email,
        ),
      ),
    );

    if (email != null) {
      await _authScreenController.sendPasswordReset(email);
    }
  }

  InputDecoration _getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.neutral500),
      prefixIcon: Icon(prefixIcon, color: AppColors.black),
      suffixIcon: suffixIcon,
      fillColor: AppColors.white,
      filled: true,
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

  Widget _passwordVisibilityButton() {
    return IconButton(
      icon: Icon(
        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        color: AppColors.black,
      ),
      onPressed: () {
        setState(() => _isPasswordVisible = !_isPasswordVisible);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: context.router.canPop()
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.neutral900),
                onPressed: () => context.router.maybePop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ListenableBuilder(
              listenable: _authScreenController,
              builder: (context, child) {
                final controller = _authScreenController;

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'QazRoute',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignIn
                            ? 'Sign in to save your profile and progress'
                            : 'Create an account',
                        style: const TextStyle(color: AppColors.neutral500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Имя — только при регистрации (необязательно)
                      if (!_isSignIn) ...[
                        TextFormField(
                          key: const ValueKey('auth_name'),
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: Validators.optionalText(),
                          style: const TextStyle(color: AppColors.neutral900),
                          cursorColor: AppColors.supplementary600,
                          decoration: _getInputDecoration(
                            hintText: 'Name (optional)',
                            prefixIcon: Icons.person,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        key: const ValueKey('auth_email'),
                        controller: _emailController,
                        style: const TextStyle(color: AppColors.neutral900),
                        cursorColor: AppColors.supplementary600,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                        decoration: _getInputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icons.email,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('auth_password'),
                        controller: _passwordController,
                        style: const TextStyle(color: AppColors.neutral900),
                        cursorColor: AppColors.supplementary600,
                        obscureText: !_isPasswordVisible,
                        autofillHints: [
                          _isSignIn
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        textInputAction: _isSignIn
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onFieldSubmitted: (_) {
                          if (_isSignIn) _submit();
                        },
                        validator: Validators.password,
                        decoration: _getInputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icons.lock,
                          suffixIcon: _passwordVisibilityButton(),
                        ),
                      ),

                      // Повтор пароля — только при регистрации
                      if (!_isSignIn) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('auth_confirm_password'),
                          controller: _confirmPasswordController,
                          style: const TextStyle(color: AppColors.neutral900),
                          cursorColor: AppColors.supplementary600,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: Validators.confirmPassword(
                            () => _passwordController.text,
                          ),
                          decoration: _getInputDecoration(
                            hintText: 'Repeat password',
                            prefixIcon: Icons.lock_outline,
                          ),
                        ),
                      ],

                      if (_isSignIn)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.isLoading
                                ? null
                                : _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.neutral900,
                            ),
                            child: const Text('Forgot password?'),
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      if (controller.errorMessage.isNotEmpty) ...[
                        _MessageBox(
                          text: controller.errorMessage,
                          color: AppColors.supplementary600900,
                          background: AppColors.supplementary60050,
                          icon: Icons.error_outline,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (controller.infoMessage.isNotEmpty) ...[
                        _MessageBox(
                          text: controller.infoMessage,
                          color: AppColors.lightGreen800,
                          background: AppColors.lightGreen50,
                          icon: Icons.mark_email_read_outlined,
                        ),
                        const SizedBox(height: 16),
                      ],

                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightGreen600,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignIn ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignIn
                                ? 'Don\'t have an account?'
                                : 'Already have an account?',
                            style: const TextStyle(
                              color: AppColors.neutral900,
                            ),
                          ),
                          TextButton(
                            onPressed: controller.isLoading ? null : _toggleMode,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.lightGreen600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              _isSignIn ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Диалог "Reset password". Отдельный StatefulWidget, чтобы поле ввода
/// само освобождало свой контроллер, когда диалог закроется.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.decoration,
  });

  final String initialEmail;
  final InputDecoration decoration;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _send() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email and we will send you a link to reset '
              'your password.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              validator: Validators.email,
              onFieldSubmitted: (_) => _send(),
              decoration: widget.decoration,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.neutral900),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _send,
          style: TextButton.styleFrom(foregroundColor: AppColors.lightGreen600),
          child: const Text(
            'Send link',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.text,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String text;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
