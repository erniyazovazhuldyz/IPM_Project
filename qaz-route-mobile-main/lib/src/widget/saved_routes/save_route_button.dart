import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/saved_routes_controller.dart';

/// US-10: «сердечко» — сохранить маршрут / убрать из сохранённых.
///
/// Стоит на карточке маршрута (Home) и в AppBar экрана маршрута. Если пользователь не вошёл —
/// открывает вход, а после входа сохраняет маршрут сам.
class SaveRouteButton extends StatelessWidget {
  const SaveRouteButton({
    super.key,
    required this.route,
    this.color = AppColors.white,
    this.controller,
  });

  final RouteModel route;
  final Color color;

  /// Для тестов; в приложении берётся [SavedRoutesController.instance].
  final SavedRoutesController? controller;

  SavedRoutesController get _controller =>
      controller ?? SavedRoutesController.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final saved = _controller.isSaved(route.id);
        return IconButton(
          key: const ValueKey('save_route_button'),
          tooltip: saved ? 'Remove from saved' : 'Save route',
          // Повторные нажатия во время запроса контроллер сам игнорирует (busy).
          onPressed: () => _onTap(context),
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: color,
          ),
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final result = await _controller.toggle(route);
    if (!context.mounted) return;

    switch (result) {
      case SaveToggleResult.saved:
        _showSnackBar(context, 'Route saved. Find it in Profile → My routes.');
      case SaveToggleResult.removed:
        _showSnackBar(context, 'Removed from saved routes.');
      case SaveToggleResult.failed:
        _showSnackBar(context, _controller.lastErrorMessage);
      case SaveToggleResult.busy:
        break;
      case SaveToggleResult.needsSignIn:
        await _signInAndSave(context);
    }
  }

  /// Не вошёл -> экран входа -> вернулся уже с аккаунтом -> сохраняем.
  Future<void> _signInAndSave(BuildContext context) async {
    _showSnackBar(context, 'Sign in to save routes.');
    await context.router.push(const AuthRoute());
    if (!context.mounted || !_controller.isSignedIn) return;

    // Сначала узнаём, что уже сохранено в аккаунте, чтобы не убрать маршрут.
    await _controller.refresh();
    if (!context.mounted || _controller.isSaved(route.id)) return;
    await _onTap(context);
  }

  static void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
