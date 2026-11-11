// Automated versions of the Sprint 2 Home screen test cases
// (docs/test_cases.md: TC-01, TC-02, TC-03).
//
// Run:  flutter test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/widget/home_screen/home_screen.dart';

final _bal = RouteModel(
  id: '10',
  slug: 'bal',
  title: 'Big Almaty Lake',
  city: 'Almaty',
  location: 'Big Almaty gorge',
  previewImageUrl: 'assets/images/trail_bal.png',
  routeImagesUrls: ['assets/images/trail_bal.png'],
  completionTime: 120,
  distance: 4.5,
  description: 'Verified test data',
  difficulty: 'moderate',
  path: [LatLng(43.05, 76.98), LatLng(43.06, 76.99)],
  isVerified: true,
);

final _unverified = RouteModel(
  id: '1',
  title: 'TEST - Medeu to Shymbulak',
  city: 'Almaty',
  location: 'Almaty, Medeu',
  previewImageUrl: 'assets/images/trail_serkebay.png',
  routeImagesUrls: [],
  completionTime: 120,
  distance: 5,
  description: '',
  path: [LatLng(43.15, 77.05)],
  isVerified: false,
);

/// Fake backend: returns the given trails, or throws [NoInternetException]
/// while [offline] is true.
class FakeTrails implements TrailsDataSource {
  FakeTrails(this.trails, {this.offline = false});

  final List<RouteModel> trails;
  bool offline;
  int calls = 0;

  @override
  Future<List<RouteModel>> getRoutes() async {
    calls++;
    if (offline) throw const NoInternetException();
    return trails;
  }

  @override
  Future<RouteModel> getRouteById(String id) async =>
      trails.firstWhere((t) => t.id == id || t.slug == id);
}

Future<void> _openHome(WidgetTester tester, TrailsDataSource source) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen(repository: source)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-01 Display verified trail (photo, name, city)',
      (tester) async {
    await _openHome(tester, FakeTrails([_bal]));

    expect(find.text('Discover Almaty'), findsOneWidget);
    expect(find.text('Popular locations'), findsOneWidget);
    expect(find.byKey(const ValueKey('trail_card_bal')), findsOneWidget);
    expect(find.byKey(const ValueKey('trail_photo_bal')), findsOneWidget);
    expect(find.text('Big Almaty Lake'), findsOneWidget);
    expect(find.text('Almaty'), findsOneWidget);
  });

  testWidgets('TC-02 Hide unverified trail', (tester) async {
    await _openHome(tester, FakeTrails([_bal, _unverified]));

    expect(find.text('Popular locations'), findsOneWidget);
    expect(find.text('Big Almaty Lake'), findsOneWidget);
    expect(find.text('TEST - Medeu to Shymbulak'), findsNothing);
  });

  testWidgets('TC-03 No internet, then Try again loads the trail',
      (tester) async {
    final source = FakeTrails([_bal], offline: true);
    await _openHome(tester, source);

    // 3. Message + button instead of empty trail cards
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const ValueKey('trail_card_bal')), findsNothing);

    // 4. Internet is back   5. Tap "Try again"
    source.offline = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsNothing);
    expect(find.text('Big Almaty Lake'), findsOneWidget);
    expect(source.calls, 2);
  });

  testWidgets('Search with no results shows the empty state', (tester) async {
    await _openHome(tester, FakeTrails([_bal]));

    await tester.enterText(find.byKey(const Key('home_search')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No trails found'), findsOneWidget);
  });

  test('Distance formatting', () {
    expect(_bal.formattedDistance(), '4.5 km');
    expect(_unverified.formattedDistance(), '5 km');
  });

  test('Network errors are recognised as "no internet"', () {
    expect(
      RoutesRepository.isNetworkError(
        Exception('ClientException: Failed to fetch'),
      ),
      isTrue,
    );
    expect(RoutesRepository.isNetworkError(Exception('Bad data')), isFalse);
  });
}
