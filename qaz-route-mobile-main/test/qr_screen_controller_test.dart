// Automated checks for the QR fixes (US-07, US-08; BUG-2, BUG-3).
//
// Run:  flutter test test/qr_screen_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/widget/qr_screen/qr_screen_controller.dart';

final _karakungei = RouteModel(
  id: '2',
  slug: 'karakungei',
  title: 'Karakungei',
  city: 'Almaty',
  location: 'Karakungei gorge',
  previewImageUrl: 'assets/trails/karakungei_1.jpg',
  routeImagesUrls: ['assets/trails/karakungei_1.jpg'],
  completionTime: 60,
  distance: 1.5,
  description: 'Verified test data',
  difficulty: 'easy',
  path: [LatLng(43.10, 77.30), LatLng(43.11, 77.31)],
  isVerified: true,
);

/// Fake backend: finds trails by id or slug, like the real repository.
class _FakeTrails implements TrailsDataSource {
  _FakeTrails(this.trails);

  final List<RouteModel> trails;
  bool offline = false;

  @override
  Future<List<RouteModel>> getRoutes() async => trails;

  @override
  Future<RouteModel> getRouteById(String id) async {
    if (offline) throw const NoInternetException();
    return trails.firstWhere(
      (t) => t.id == id || t.slug == id,
      orElse: () => throw StateError('Trail "$id" not found'),
    );
  }
}

void main() {
  test('Correct QR opens the trail (US-07)', () async {
    final controller = QrScreenController(repository: _FakeTrails([_karakungei]));

    final route = await controller.getRouteById('karakungei');

    expect(route?.slug, 'karakungei');
    expect(controller.state, QrScreenState.found);
    expect(controller.scannedRoute?.slug, 'karakungei');
  });

  test('Wrong QR gives "Route not found" (US-08, BUG-2)', () async {
    final controller = QrScreenController(repository: _FakeTrails([_karakungei]));

    final route = await controller.getRouteById('hello123');

    expect(route, isNull);
    expect(controller.state, QrScreenState.notFound);
    expect(controller.errorMessage, 'Route not found');
  });

  test('Wrong QR after a correct one does not reopen the old trail (BUG-3)',
      () async {
    final controller = QrScreenController(repository: _FakeTrails([_karakungei]));

    await controller.getRouteById('karakungei');
    final route = await controller.getRouteById('hello123');

    expect(route, isNull);
    expect(controller.scannedRoute, isNull);
    expect(controller.state, QrScreenState.notFound);
  });

  test('No internet keeps the user on the QR screen with a message', () async {
    final source = _FakeTrails([_karakungei])..offline = true;
    final controller = QrScreenController(repository: source);

    final route = await controller.getRouteById('karakungei');

    expect(route, isNull);
    expect(controller.state, QrScreenState.noInternet);
    expect(controller.errorMessage, startsWith('No internet connection'));
  });

  test('Spaces around the QR text are ignored', () async {
    final controller = QrScreenController(repository: _FakeTrails([_karakungei]));

    final route = await controller.getRouteById('  karakungei \n');

    expect(route?.slug, 'karakungei');
  });
}
