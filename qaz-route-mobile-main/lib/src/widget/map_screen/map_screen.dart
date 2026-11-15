import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:qaz_route_mobile/src/core/app_colors.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/router/app_router.dart';
import 'package:qaz_route_mobile/src/widget/common/trail_image.dart';
import 'package:qaz_route_mobile/src/widget/map_screen/map_focus.dart';
import 'package:qaz_route_mobile/src/widget/map_screen/map_screen_controller.dart';

@RoutePage()
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenController _mapScreenController;
  final MapController _mapController = MapController();

  /// Current GPS position (one-time fix, not live tracking).
  LatLng? _myPosition;
  bool _locating = false;

  /// The camera can be moved only after the map is ready.
  bool _mapReady = false;

  static const _almaty = LatLng(43.23011246725963, 76.91868747847725);

  @override
  void initState() {
    super.initState();
    _mapScreenController = MapScreenController(repository: RoutesRepository());
    _mapScreenController.loadRoutes();
    _locateMe(moveCamera: false);

    // "Open Map" from a trail screen (US-04).
    MapFocus.instance.addListener(_onMapFocus);
    final focused = MapFocus.instance.route;
    if (focused != null) _mapScreenController.showRoute(focused);
  }

  void _onMapFocus() {
    final route = MapFocus.instance.route;
    if (route == null) return;
    _mapScreenController.showRoute(route);
    if (_mapReady) _fitRoute(route);
  }

  /// Move the camera so the whole trail line is visible.
  void _fitRoute(RouteModel route) {
    if (route.path.length > 1) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: route.path,
          padding: const EdgeInsets.fromLTRB(48, 160, 48, 120),
        ),
      );
    } else if (route.path.isNotEmpty) {
      _mapController.move(route.path.first, 15);
    }
  }

  Future<void> _locateMe({bool moveCamera = true}) async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage(
          'Turn on location to see your position.',
          actionLabel: 'Settings',
          onAction: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is off for QazRoute.',
          actionLabel: 'Settings',
          onAction: Geolocator.openAppSettings,
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission is needed to show your position.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;

      final point = LatLng(position.latitude, position.longitude);
      setState(() => _myPosition = point);
      if (moveCamera) _mapController.move(point, 15);
    } catch (e) {
      _showMessage('Could not get your location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(
    String text, {
    String? actionLabel,
    Future<bool> Function()? onAction,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(seconds: onAction == null ? 4 : 8),
        action: onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel ?? 'Settings',
                onPressed: () async {
                  try {
                    await onAction();
                  } catch (_) {
                    // Not supported on this platform (e.g. web).
                  }
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    MapFocus.instance.removeListener(_onMapFocus);
    _mapScreenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.lightGreen600,
        surfaceTintColor: AppColors.lightGreen600,
        centerTitle: false,
        title: Text(
          'Map',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      // The app's bottom menu is drawn over this screen (extendBody), so lift
      // the My location button above it; otherwise it is hidden behind it.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.lightGreen600,
          tooltip: 'My location',
          onPressed: _locating ? null : _locateMe,
          child: _locating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.my_location),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _mapScreenController,
          builder: (context, child) {
            final selected = _mapScreenController.selectedRoute;

            return Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _almaty,
                      initialZoom: 10,
                      onMapReady: () {
                        _mapReady = true;
                        final focused = MapFocus.instance.route;
                        if (focused != null) _fitRoute(focused);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'kz.kbtu.qaz_route_mobile',
                      ),
                      if (selected != null && selected.path.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: selected.path,
                              color: AppColors.supplementary600700,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (final route in _mapScreenController.routes)
                            if (route.path.isNotEmpty)
                              Marker(
                                point: route.path.first,
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: GestureDetector(
                                  onTap: () =>
                                      _mapScreenController.selectRoute(route),
                                  child: Tooltip(
                                    message: route.title,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.supplementary600700,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ),
                          if (_myPosition != null)
                            Marker(
                              point: _myPosition!,
                              width: 24,
                              height: 24,
                              child: const _MyLocationDot(),
                            ),
                        ],
                      ),
                      const SimpleAttributionWidget(
                        source: Text('OpenStreetMap contributors'),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: MapScreenRoutePreview(route: selected),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'You are here',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class MapScreenRoutePreview extends StatelessWidget {
  const MapScreenRoutePreview({super.key, required this.route});

  final RouteModel? route;

  @override
  Widget build(BuildContext context) {
    if (route == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        context.router.navigate(RouteDetailsRoute(route: route!));
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TrailImage(
                    route!.previewImageUrl,
                    width: 64,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        route!.title,
                        style: const TextStyle(
                          color: AppColors.neutral900,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route!.location,
                        style: TextStyle(
                          color: AppColors.neutral900,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      route!.formattedDistance(),
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 48),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duration', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      route!.formattedCompletionTime(),
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
