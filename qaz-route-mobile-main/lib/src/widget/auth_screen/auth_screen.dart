import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/auth_screen/auth_screen_controller.dart';

@RoutePage()
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final AuthScreenController _authScreenController;
  bool _isPasswordVisible = false;
  bool _isSignIn = true;

  @override
  void initState() {
    super.initState();
    _authScreenController = AuthScreenController(repository: AuthRepository());
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _authScreenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.neutral900),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ListenableBuilder(
            listenable: _authScreenController,
            builder: (context, child) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: AppColors.neutral900),
                      cursorColor: AppColors.supplementary600,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _getInputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icons.email,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: AppColors.neutral900),
                      cursorColor: AppColors.supplementary600,
                      obscureText: !_isPasswordVisible,
                      decoration: _getInputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_authScreenController.errorMessage.isNotEmpty) ...[
                      Text(
                        _authScreenController.errorMessage,
                        style: TextStyle(color: AppColors.supplementary600900),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ElevatedButton(
                      onPressed: () async {
                        switch (_authScreenController.state) {
                          case AuthScreenState.loading:
                            return;
                          case AuthScreenState.idle || AuthScreenState.error:
                            final isSuccess = await () async {
                              if (_isSignIn) {
                                return await _authScreenController.signIn(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );
                              } else {
                                return await _authScreenController.signUp(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );
                              }
                            }();

                            if (isSuccess && context.mounted) {
                              context.router.replace(AppRoute());
                            }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGreen600,
                        foregroundColor: AppColors.neutral900,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: switch (_authScreenController.state) {
                        AuthScreenState.loading => const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        AuthScreenState.idle || AuthScreenState.error => Text(
                          _isSignIn ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignIn
                              ? 'Don\'t have an account? '
                              : 'Already have an account?',
                          style: TextStyle(color: AppColors.neutral900),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isSignIn = !_isSignIn);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.neutral900,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            _isSignIn ? 'Sign Up' : 'Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
