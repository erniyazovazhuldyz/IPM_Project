// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AppScreen]
class AppRoute extends PageRouteInfo<void> {
  const AppRoute({List<PageRouteInfo>? children})
    : super(AppRoute.name, initialChildren: children);

  static const String name = 'AppRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppScreen();
    },
  );
}

/// generated route for
/// [AuthScreen]
class AuthRoute extends PageRouteInfo<void> {
  const AuthRoute({List<PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AuthScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [HomeScreenWrapper]
class HomeRouteWrapper extends PageRouteInfo<void> {
  const HomeRouteWrapper({List<PageRouteInfo>? children})
    : super(HomeRouteWrapper.name, initialChildren: children);

  static const String name = 'HomeRouteWrapper';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return WrappedRoute(child: const HomeScreenWrapper());
    },
  );
}

/// generated route for
/// [MapScreen]
class MapRoute extends PageRouteInfo<void> {
  const MapRoute({List<PageRouteInfo>? children})
    : super(MapRoute.name, initialChildren: children);

  static const String name = 'MapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MapScreen();
    },
  );
}

/// generated route for
/// [PremiumScreen]
class PremiumRoute extends PageRouteInfo<void> {
  const PremiumRoute({List<PageRouteInfo>? children})
    : super(PremiumRoute.name, initialChildren: children);

  static const String name = 'PremiumRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PremiumScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [ProfileScreenWrapper]
class ProfileRouteWrapper extends PageRouteInfo<void> {
  const ProfileRouteWrapper({List<PageRouteInfo>? children})
    : super(ProfileRouteWrapper.name, initialChildren: children);

  static const String name = 'ProfileRouteWrapper';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return WrappedRoute(child: const ProfileScreenWrapper());
    },
  );
}

/// generated route for
/// [QrScreen]
class QrRoute extends PageRouteInfo<void> {
  const QrRoute({List<PageRouteInfo>? children})
    : super(QrRoute.name, initialChildren: children);

  static const String name = 'QrRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const QrScreen();
    },
  );
}

/// generated route for
/// [RouteDetailsScreen]
class RouteDetailsRoute extends PageRouteInfo<RouteDetailsRouteArgs> {
  RouteDetailsRoute({
    Key? key,
    required RouteModel route,
    List<PageRouteInfo>? children,
  }) : super(
         RouteDetailsRoute.name,
         args: RouteDetailsRouteArgs(key: key, route: route),
         initialChildren: children,
       );

  static const String name = 'RouteDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RouteDetailsRouteArgs>();
      return RouteDetailsScreen(key: args.key, route: args.route);
    },
  );
}

class RouteDetailsRouteArgs {
  const RouteDetailsRouteArgs({this.key, required this.route});

  final Key? key;

  final RouteModel route;

  @override
  String toString() {
    return 'RouteDetailsRouteArgs{key: $key, route: $route}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RouteDetailsRouteArgs) return false;
    return key == other.key && route == other.route;
  }

  @override
  int get hashCode => key.hashCode ^ route.hashCode;
}
