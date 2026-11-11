import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
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
      repository: AuthRepository(),
    )..getUser();
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
        title: Text(
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
    final user = profileScreenController.user;

    if (user == null) {
      return const Center(child: Text('No user data available'));
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_box, size: 96, color: AppColors.neutral500),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.neutral900,
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'SETTINGS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(height: 0, thickness: 1),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: Size(double.maxFinite, 48),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Personal information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
                Expanded(child: SizedBox()),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.black),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1),
          TextButton(
            onPressed: () {
              context.router.navigate(PremiumRoute());
            },
            style: TextButton.styleFrom(
              minimumSize: Size(double.maxFinite, 48),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.black,
                  ),
                ),
                Expanded(child: SizedBox()),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.black),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1),
          Expanded(child: SizedBox()),
          ElevatedButton(
            onPressed: () async {
              final isSuccess = await profileScreenController.signOut();

              if (isSuccess && context.mounted) {
                context.router.replace(AuthRoute());
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.maxFinite, 48),
              backgroundColor: AppColors.neutral500,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.supplementary600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 8,
            ),
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(profileScreenController.errorMessage),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: profileScreenController.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
