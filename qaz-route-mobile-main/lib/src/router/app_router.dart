import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/widget/app.dart';
import 'package:qaz_route_mobile/src/widget/auth_screen/auth_screen.dart';
import 'package:qaz_route_mobile/src/widget/home_screen/home_screen.dart';
import 'package:qaz_route_mobile/src/widget/home_screen/home_screen_wrapper.dart';
import 'package:qaz_route_mobile/src/widget/map_screen/map_screen.dart';
import 'package:qaz_route_mobile/src/widget/premium_screen/premium_screen.dart';
import 'package:qaz_route_mobile/src/widget/profile_screen/profile_screen.dart';
import 'package:qaz_route_mobile/src/widget/profile_screen/profile_screen_wrapper.dart';
import 'package:qaz_route_mobile/src/widget/qr_screen/qr_screen.dart';
import 'package:qaz_route_mobile/src/widget/route_details_screen/route_details_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        // Страница авторизации
        // Она больше не открывается автоматически
        AutoRoute(
          page: AuthRoute.page,
          path: '/auth',
        ),

        // Главное приложение
        AutoRoute(
          page: AppRoute.page,
          path: '/',
          initial: true,
          children: [
            // Home
            AutoRoute(
              page: HomeRouteWrapper.page,
              children: [
                AutoRoute(
                  page: HomeRoute.page,
                  path: 'home',
                  initial: true,
                ),
                AutoRoute(
                  page: RouteDetailsRoute.page,
                  path: 'details',
                ),
              ],
            ),

            // Map
            AutoRoute(
              page: MapRoute.page,
              path: 'map',
            ),

            // QR
            AutoRoute(
              page: QrRoute.page,
              path: 'qr',
            ),

            // Profile
            AutoRoute(
              page: ProfileRouteWrapper.page,
              children: [
                AutoRoute(
                  page: ProfileRoute.page,
                  path: 'profile',
                  initial: true,
                ),
              ],
            ),
          ],
        ),

        // Premium
        CustomRoute(
          page: PremiumRoute.page,
          path: '/premium',
          durationInMilliseconds: 300,
          reverseDurationInMilliseconds: 300,
          transitionsBuilder: TransitionsBuilders.slideBottom,
        ),
      ];
}

class HomeTab {}