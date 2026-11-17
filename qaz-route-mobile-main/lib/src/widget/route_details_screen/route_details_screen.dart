import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/trail_image.dart';
import 'package:qaz_route_mobile/src/widget/map_screen/map_focus.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/save_route_button.dart';

@RoutePage()
class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({super.key, required this.route});

  final RouteModel route;

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  RouteModel get route => widget.route;

  @override
  void initState() {
    super.initState();
    // US-04: the trail opened here is the one the Map tab (bottom menu)
    // shows. Done after the first frame so the map is not changed mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MapFocus.instance.show(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Route Details',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        // US-10: сохранить маршрут («сердечко»).
        actions: [SaveRouteButton(route: route)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              route.displayCity,
              style: const TextStyle(fontSize: 14, color: AppColors.neutral900),
            ),
            const SizedBox(height: 12),
            _VerifiedBadge(route: route),
            const SizedBox(height: 24),
            Text(
              'PHOTOS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              child: PageView.builder(
                itemCount: route.routeImagesUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TrailImage(route.routeImagesUrls[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ROUTE INFORMATION',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.hiking, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Hiking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Expanded(child: SizedBox.shrink()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      route.formattedDistance(),
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      route.formattedCompletionTime(),
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
            ),
            if (route.formattedDifficulty() != null ||
                route.elevationGainM != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (route.formattedDifficulty() != null)
                    _DetailValue(
                      label: 'Difficulty',
                      value: route.formattedDifficulty()!,
                    ),
                  if (route.formattedDifficulty() != null)
                    const SizedBox(width: 32),
                  if (route.elevationGainM != null)
                    _DetailValue(
                      label: 'Elevation gain',
                      value: '+${route.elevationGainM} m',
                    ),
                  if (route.maxElevationM != null) ...[
                    const SizedBox(width: 32),
                    _DetailValue(
                      label: 'Max height',
                      value: '${route.maxElevationM} m',
                    ),
                  ],
                ],
              ),
            ],
            if (route.formattedStartPoint() != null) ...[
              const SizedBox(height: 20),
              _DetailValue(
                label: 'Start point',
                value: route.location.trim().isEmpty
                    ? route.formattedStartPoint()!
                    : '${route.location}\n${route.formattedStartPoint()}',
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'DESCRIPTION',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              route.description,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 32),

            // Main action: open the Map tab with THIS trail's line (US-04).
            ElevatedButton(
              onPressed: () {
                MapFocus.instance.show(route);
                context.router.navigate(const MapRoute());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.maxFinite, 48),
                backgroundColor: AppColors.lightGreen600,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.lightGreen600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 8,
              ),
              child: Text(
                'Start Route',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Future feature (live tracking is out of the MVP scope):
            // for now it opens the Premium screen.
            ElevatedButton(
              onPressed: () {
                context.router.navigate(PremiumRoute());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.maxFinite, 48),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.lightGreen600,
                disabledBackgroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.lightGreen600, width: 3)
                ),
                elevation: 8,
              ),
              child: Text(
                'Start Tracking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// "Verified · last check 20.10.2026" or "Not verified yet" (US-03).
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.route});

  final RouteModel route;

  @override
  Widget build(BuildContext context) {
    final date = route.formattedVerifiedAt();
    final verified = route.isVerified;

    final String text;
    if (!verified) {
      text = 'Not verified yet';
    } else if (date != null) {
      text = 'Verified · last check $date';
    } else {
      text = 'Verified';
    }

    final color = verified ? AppColors.lightGreen600 : AppColors.neutral500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.help_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

  }
}
