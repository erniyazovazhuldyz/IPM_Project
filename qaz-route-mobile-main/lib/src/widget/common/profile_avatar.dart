import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/profile_model.dart';

/// Круглый аватар: фото из Storage, а если его нет — инициалы.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 40});

  final ProfileModel? profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    final initials = Text(
      profile?.initials ?? '?',
      style: TextStyle(
        fontSize: radius * 0.7,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    );

    if (profile == null || !profile.hasAvatar) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.lightGreen600,
        child: initials,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.neutral100,
      child: ClipOval(
        child: Image.network(
          profile.avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Пока грузится — крутилка, если ссылка битая — инициалы.
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lightGreen600,
                  ),
                ),
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.lightGreen600,
            alignment: Alignment.center,
            child: initials,
          ),
        ),
      ),
    );
  }
}
