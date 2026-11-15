import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/profile_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/profile_avatar.dart';
import 'package:qaz_route_mobile/src/widget/profile_screen/profile_screen_controller.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileScreenController _profileScreenController;

  @override
  void initState() {
    super.initState();
    _profileScreenController = ProfileScreenController(
      authRepository: AuthRepository(),
      profileRepository: ProfileRepository(),
    )..start();
  }

  @override
  void dispose() {
    _profileScreenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _profileScreenController,
          builder: (context, child) {
            switch (_profileScreenController.state) {
              case ProfileScreenState.loading:
                return const _ProfileScreenLoading();
              case ProfileScreenState.signedOut:
                return const _ProfileScreenSignedOut();
              case ProfileScreenState.error:
                return _ProfileScreenError(
                  profileScreenController: _profileScreenController,
                );
              case ProfileScreenState.idle:
                return _ProfileScreenIdle(
                  profileScreenController: _profileScreenController,
                );
            }
          },
        ),
      ),
    );
  }
}

class _ProfileScreenIdle extends StatelessWidget {
  const _ProfileScreenIdle({required this.profileScreenController});

  final ProfileScreenController profileScreenController;

  @override
  Widget build(BuildContext context) {
    final profile = profileScreenController.profile!;

    return RefreshIndicator(
      color: AppColors.lightGreen600,
      onRefresh: profileScreenController.refresh,
      child: ListView(
        // bottom padding: нижнее меню перекрывает контент (extendBody: true)
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ---------- Пара 1: данные пользователя ----------
          Row(
            children: [
              ProfileAvatar(profile: profile, radius: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      key: const ValueKey('profile_name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    if (profile.hasName && profile.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.email!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                    if (profile.city != null &&
                        profile.city!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              profile.city!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!profile.hasName) ...[
            const SizedBox(height: 16),
            _CompleteProfileHint(
              onTap: () => _openPersonalInfo(context),
            ),
          ],

          // ---------- Пара 2: сюда добавить разделы ----------
          // "Favorites" и "History / stats" (пройденные маршруты).
          // Например: const SizedBox(height: 32), FavoritesSection(), ...

          const SizedBox(height: 32),
          const Text(
            'SETTINGS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(height: 0, thickness: 1),
          _SettingsTile(
            title: 'Personal information',
            onPressed: () => _openPersonalInfo(context),
          ),
          const Divider(height: 0, thickness: 1),
          _SettingsTile(
            title: 'Subscription',
            onPressed: () => context.router.navigate(PremiumRoute()),
          ),
          const Divider(height: 0, thickness: 1),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _confirmSignOut(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.maxFinite, 48),
              backgroundColor: AppColors.neutral500,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPersonalInfo(BuildContext context) async {
    await context.router.push(const PersonalInfoRoute());
    // Вернулись с экрана редактирования — подтягиваем свежие данные.
    await profileScreenController.refresh();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Sign out?'),
        content: const Text('You can sign in again at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.neutral900),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.supplementary600900,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final isSuccess = await profileScreenController.signOut();
    if (!isSuccess && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Try again.')),
      );
    }
  }
}

class _CompleteProfileHint extends StatelessWidget {
  const _CompleteProfileHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightGreen50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.lightGreen800),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add your name and photo',
                  style: TextStyle(color: AppColors.lightGreen800),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.lightGreen800,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.maxFinite, 48),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.black,
          ),
        ],
      ),
    );
  }
}

/// Пользователь не вошёл: объясняем, зачем входить, и даём кнопку.
class _ProfileScreenSignedOut extends StatelessWidget {
  const _ProfileScreenSignedOut();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 96,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 16),
            const Text(
              'You are not signed in',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to keep your profile, favorite trails and hiking '
              'history on all your devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral500),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const ValueKey('profile_sign_in_button'),
              onPressed: () => context.router.push(const AuthRoute()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.maxFinite, 48),
                backgroundColor: AppColors.lightGreen600,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign In / Sign Up',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreenLoading extends StatelessWidget {
  const _ProfileScreenLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.lightGreen600),
    );
  }
}

class _ProfileScreenError extends StatelessWidget {
  const _ProfileScreenError({required this.profileScreenController});

  final ProfileScreenController profileScreenController;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.neutral500,
            ),
            const SizedBox(height: 16),
            Text(
              profileScreenController.errorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: profileScreenController.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen600,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Try again'),
            ),
            TextButton(
              onPressed: profileScreenController.signOut,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral500,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
