import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/trail_image.dart';

@RoutePage()
class RouteDetailsScreen extends StatelessWidget {
  const RouteDetailsScreen({super.key, required this.route});

  final RouteModel route;

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

            ElevatedButton(
              onPressed: () {
                context.router.navigate(PremiumRoute());
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
            ElevatedButton(
              onPressed: () {
                context.router.navigate(MapRoute());
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
                'Open Map',
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
