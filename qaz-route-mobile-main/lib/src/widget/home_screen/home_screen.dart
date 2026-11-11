import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_assets.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/trail_image.dart';
import 'package:qaz_route_mobile/src/widget/home_screen/home_screen_controller.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  /// For tests. In the app the Supabase [RoutesRepository] is used.
  final TrailsDataSource? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeScreenController _homeScreenController;

  @override
  void initState() {
    super.initState();
    _homeScreenController = HomeScreenController(
      repository: widget.repository ?? RoutesRepository(),
    )..loadRoutes();
  }

  @override
  void dispose() {
    _homeScreenController.dispose();
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
          'Discover Almaty',
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
          listenable: _homeScreenController,
          builder: (context, child) {
            switch (_homeScreenController.state) {
              case HomeScreenState.loading:
                return const _HomeScreenLoading();
              case HomeScreenState.noInternet:
                return _HomeScreenMessage(
                  key: const Key('home_no_internet'),
                  icon: AppAssets.noInternet,
                  title: 'No internet connection',
                  subtitle: 'Check Wi-Fi or mobile data and try again.',
                  onRetry: _homeScreenController.refreshRoutes,
                );
              case HomeScreenState.error:
                return _HomeScreenMessage(
                  key: const Key('home_error'),
                  icon: AppAssets.empty,
                  title: 'Something went wrong',
                  subtitle: _homeScreenController.errorMessage,
                  onRetry: _homeScreenController.refreshRoutes,
                );
              case HomeScreenState.idle:
                return _HomeScreenIdle(
                  homeScreenController: _homeScreenController,
                );
            }
          },
        ),
      ),
    );
  }
}

class _HomeScreenIdle extends StatelessWidget {
  const _HomeScreenIdle({required this.homeScreenController});

  final HomeScreenController homeScreenController;

  @override
  Widget build(BuildContext context) {
    final routes = homeScreenController.routes;

    return RefreshIndicator(
      color: AppColors.lightGreen600,
      onRefresh: homeScreenController.refreshRoutes,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: _SearchBar(controller: homeScreenController),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Popular locations',
                key: Key('popular_locations_title'),
                style: TextStyle(
                  color: AppColors.neutral900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (routes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _HomeScreenMessage(
                key: const Key('home_empty'),
                icon: AppAssets.empty,
                title: homeScreenController.hasActiveFilter
                    ? 'No trails found'
                    : 'No verified trails yet',
                subtitle: homeScreenController.hasActiveFilter
                    ? 'Try another name or filter.'
                    : 'Verified trails will appear here.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.paddingOf(context).bottom + 80,
              ),
              sliver: SliverList.separated(
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  return _TrailCard(route: routes[index]);
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.neutral100),
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('home_search'),
            onChanged: controller.searchRoutes,
            style: const TextStyle(color: AppColors.neutral900),
            cursorColor: AppColors.lightGreen600,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search trails',
              hintStyle: const TextStyle(color: AppColors.neutral500),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(10),
                child: Image(
                  image: AssetImage(AppAssets.search),
                  width: 24,
                  height: 24,
                ),
              ),
              fillColor: AppColors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.lightGreen600,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: controller.difficulty != null,
          backgroundColor: AppColors.lightGreen600,
          smallSize: 10,
          child: IconButton.outlined(
            key: const Key('home_filter'),
            tooltip: 'Filter',
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.neutral100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => _showFilter(context),
            icon: const Image(
              image: AssetImage(AppAssets.filter),
              width: 26,
              height: 26,
            ),
          ),
        ),
      ],
    );
  }

  void _showFilter(BuildContext context) {
    final options = controller.availableDifficulties;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget chip(String label, String? value) {
          final selected = controller.difficulty == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: AppColors.lightGreen100,
            checkmarkColor: AppColors.lightGreen800,
            onSelected: (_) {
              controller.setDifficulty(value);
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Difficulty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip('All', null),
                    for (final d in options)
                      chip(d[0].toUpperCase() + d.substring(1), d),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeScreenLoading extends StatelessWidget {
  const _HomeScreenLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.lightGreen600),
    );
  }
}

/// Full-screen message with an icon: no internet / error / empty list.
class _HomeScreenMessage extends StatelessWidget {
  const _HomeScreenMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 72, height: 72),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutral900,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral500, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('home_try_again'),
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightGreen600,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrailCard extends StatelessWidget {
  const _TrailCard({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    final difficulty = route.formattedDifficulty();

    return Material(
      key: ValueKey('trail_card_${route.slug ?? route.id}'),
      color: AppColors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.router.navigate(RouteDetailsRoute(route: route));
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TrailImage(
                  route.previewImageUrl,
                  key: ValueKey('trail_photo_${route.slug ?? route.id}'),
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset(AppAssets.pin, width: 16, height: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            route.displayCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.neutral500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoChip(route.formattedDistance()),
                        _InfoChip(route.formattedCompletionTime()),
                        if (difficulty != null) _InfoChip(difficulty),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightGreen50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.lightGreen800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
