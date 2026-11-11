import 'package:auto_route/auto_route.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuthenticated = AuthRepository().isAuthenticated();

    if (isAuthenticated) {
      resolver.next(true);
    } else {
      router.push(AuthRoute());
    }
  }
}
