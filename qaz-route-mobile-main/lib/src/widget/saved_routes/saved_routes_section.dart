import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/trail_image.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/saved_routes_controller.dart';

/// US-10: раздел «MY ROUTES» (сохранённые маршруты) на экране Profile.
/// Показывается только вошедшему пользователю.
class SavedRoutesSection extends StatelessWidget {
  const SavedRoutesSection({super.key, this.controller});

  /// Для тестов; в приложении берётся [SavedRoutesController.instance].
  final SavedRoutesController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? SavedRoutesController.instance;

    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'MY ROUTES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (c.state == SavedRoutesState.idle && c.routes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${c.routes.length}',
                    key: const ValueKey('saved_routes_count'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _buildBody(context, c),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SavedRoutesController c) {
    switch (c.state) {
      case SavedRoutesState.signedOut:
        return const SizedBox.shrink();
      case SavedRoutesState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.lightGreen600),
          ),
        );
      case SavedRoutesState.error:
        return Row(
          children: [
            Expanded(
              child: Text(
                c.errorMessage,
                style: const TextStyle(color: AppColors.neutral500),
              ),
            ),
            TextButton(
              onPressed: c.refresh,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lightGreen600,
              ),
              child: const Text('Try again'),
            ),
          ],
        );
      case SavedRoutesState.idle:
        if (c.routes.isEmpty) {
          return const _EmptySavedRoutes();
        }
        return Column(
          children: [
            for (final route in c.routes)
              _SavedRouteTile(route: route, controller: c),
          ],
        );
    }
  }
}

class _EmptySavedRoutes extends StatelessWidget {
  const _EmptySavedRoutes();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('saved_routes_empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_border, color: AppColors.lightGreen800),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No saved routes yet. Tap ♡ on a trail to save it.',
              style: TextStyle(color: AppColors.lightGreen800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteTile extends StatelessWidget {
  const _SavedRouteTile({required this.route, required this.controller});

  final RouteModel route;
  final SavedRoutesController controller;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      route.displayCity,
      route.formattedDistance(),
      if (route.formattedDifficulty() != null) route.formattedDifficulty()!,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      // Экран маршрута живёт во вкладке Home — navigate сам переключит вкладку
      // (так же открывают маршрут Map и QR).
      onTap: () => context.router.navigate(RouteDetailsRoute(route: route)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TrailImage(route.previewImageUrl, width: 64, height: 64),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove from saved',
              onPressed: () => _remove(context),
              icon: const Icon(Icons.favorite, color: AppColors.lightGreen600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final result = await controller.toggle(route);
    if (!context.mounted) return;
    final text = switch (result) {
      SaveToggleResult.removed => 'Removed from saved routes.',
      SaveToggleResult.failed => controller.lastErrorMessage,
      _ => null,
    };
    if (text == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
