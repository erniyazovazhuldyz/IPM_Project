import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_assets.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router.config(
        navigatorObservers: () => [AutoRouteObserver()],
      ),
    );
  }
}

@RoutePage()
class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      extendBody: true,
      backgroundColor: AppColors.white,
      animationDuration: Duration.zero,
      routes: const [HomeRoute(), MapRoute(), QrRoute(), ProfileRoute()],
      bottomNavigationBuilder: (_, tabsRouter) {
        return NavigationBar(
          selectedIndex: tabsRouter.activeIndex,
          onDestinationSelected: (index) {
            tabsRouter.setActiveIndex(index);
          },
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.lightGreen600,
          labelTextStyle: WidgetStateMapper({
            WidgetState.selected: TextStyle(color: AppColors.lightGreen600),
            WidgetState.any: TextStyle(color: AppColors.neutral500),
          }),
          destinations: [
            NavigationDestination(
              icon: const ImageIcon(
                AssetImage(AppAssets.navHome),
                color: AppColors.neutral500,
              ),
              selectedIcon: const ImageIcon(
                AssetImage(AppAssets.navHome),
                color: AppColors.white,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const ImageIcon(
                AssetImage(AppAssets.navMap),
                color: AppColors.neutral500,
              ),
              selectedIcon: const ImageIcon(
                AssetImage(AppAssets.navMap),
                color: AppColors.white,
              ),
              label: 'Map',
            ),
            NavigationDestination(
              icon: const ImageIcon(
                AssetImage(AppAssets.navQr),
                color: AppColors.neutral500,
              ),
              selectedIcon: const ImageIcon(
                AssetImage(AppAssets.navQr),
                color: AppColors.white,
              ),
              label: 'QR',
            ),
            NavigationDestination(
              icon: const ImageIcon(
                AssetImage(AppAssets.navProfile),
                color: AppColors.neutral500,
              ),
              selectedIcon: const ImageIcon(
                AssetImage(AppAssets.navProfile),
                color: AppColors.white,
              ),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}
