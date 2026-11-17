// US-10 «Сохранение маршрутов»: автотесты без сети и без Supabase.
// Ручные тест-кейсы TC-11 … TC-15: docs/us10_saved_routes.md
//
// Run:  flutter test test/saved_routes_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:qaz_route_mobile/src/repository/saved_routes_repository.dart';
import 'package:qaz_route_mobile/src/widget/home_screen/home_screen.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/save_route_button.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/saved_routes_controller.dart';
import 'package:qaz_route_mobile/src/widget/saved_routes/saved_routes_section.dart';

RouteModel _trail(String id, String title) => RouteModel(
      id: id,
      slug: title.toLowerCase(),
      title: title,
      city: 'Almaty',
      location: 'Medeu',
      previewImageUrl: 'assets/trails/karakungei_1.jpg',
      routeImagesUrls: const ['assets/trails/karakungei_1.jpg'],
      completionTime: 60,
      distance: 1.5,
      description: '',
      difficulty: 'easy',
      path: [LatLng(43.16, 77.05)],
      isVerified: true,
    );

final _karakungei = _trail('2', 'Karakungei');
final _bal = _trail('10', 'BAL');

/// Фейковая таблица saved_routes в памяти.
class FakeSavedRoutes implements SavedRoutesDataSource {
  FakeSavedRoutes(this.catalog, {List<String> savedIds = const []})
      : savedIds = [...savedIds];

  final List<RouteModel> catalog;
  final List<String> savedIds;
  bool offline = false;
  int loadCalls = 0;

  @override
  Future<List<RouteModel>> getSavedRoutes() async {
    loadCalls++;
    if (offline) throw const NoInternetException();
    return [
      for (final id in savedIds.reversed) catalog.firstWhere((r) => r.id == id),
    ];
  }

  @override
  Future<void> saveRoute(String routeId) async {
    if (offline) throw const NoInternetException();
    if (!savedIds.contains(routeId)) savedIds.add(routeId);
  }

  @override
  Future<void> removeRoute(String routeId) async {
    if (offline) throw const NoInternetException();
    savedIds.remove(routeId);
  }
}

/// Фейковый каталог маршрутов для экрана Home.
class FakeTrails implements TrailsDataSource {
  FakeTrails(this.trails);

  final List<RouteModel> trails;

  @override
  Future<List<RouteModel>> getRoutes() async => trails;

  @override
  Future<RouteModel> getRouteById(String id) async =>
      trails.firstWhere((t) => t.id == id);
}

void main() {
  late StreamController<String?> auth;
  String? userId;

  SavedRoutesController makeController(FakeSavedRoutes source) {
    return SavedRoutesController(
      dataSource: source,
      currentUserId: () => userId,
      userIdChanges: auth.stream,
    );
  }

  setUp(() {
    auth = StreamController<String?>.broadcast();
    userId = null;
  });

  tearDown(() => auth.close());

  group('SavedRoutesController', () {
    test('signed out: nothing is saved and saving asks to sign in', () async {
      final source = FakeSavedRoutes([_karakungei]);
      final c = makeController(source);

      expect(c.state, SavedRoutesState.signedOut);
      expect(c.isSaved('2'), isFalse);
      expect(await c.toggle(_karakungei), SaveToggleResult.needsSignIn);
      expect(source.savedIds, isEmpty);
    });

    test('signed in: loads my saved routes', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei, _bal], savedIds: ['2']);
      final c = makeController(source);
      await pumpEventQueue();

      expect(c.state, SavedRoutesState.idle);
      expect(c.isSaved('2'), isTrue);
      expect(c.isSaved('10'), isFalse);
    });

    test('heart: save, then remove', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei, _bal]);
      final c = makeController(source);
      await pumpEventQueue();

      expect(await c.toggle(_bal), SaveToggleResult.saved);
      expect(c.isSaved('10'), isTrue);
      expect(source.savedIds, ['10']);

      expect(await c.toggle(_bal), SaveToggleResult.removed);
      expect(c.isSaved('10'), isFalse);
      expect(source.savedIds, isEmpty);
    });

    test('newest saved route is shown first', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei, _bal]);
      final c = makeController(source);
      await pumpEventQueue();

      await c.toggle(_karakungei);
      await c.toggle(_bal);
      expect(c.routes.map((r) => r.title), ['BAL', 'Karakungei']);
    });

    test('no internet: heart goes back and an error is shown', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei]);
      final c = makeController(source);
      await pumpEventQueue();

      source.offline = true;
      expect(await c.toggle(_karakungei), SaveToggleResult.failed);
      expect(c.isSaved('2'), isFalse);
      expect(c.lastErrorMessage, contains('No internet'));
    });

    test('sign out clears the list, sign in of another user reloads', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei], savedIds: ['2']);
      final c = makeController(source);
      await pumpEventQueue();
      expect(c.isSaved('2'), isTrue);

      userId = null;
      auth.add(null);
      await pumpEventQueue();
      expect(c.state, SavedRoutesState.signedOut);
      expect(c.routes, isEmpty);

      source.savedIds.clear(); // у пользователя B ничего не сохранено
      userId = 'user-b';
      auth.add('user-b');
      await pumpEventQueue();
      expect(c.state, SavedRoutesState.idle);
      expect(c.isSaved('2'), isFalse);
    });

    test('token refresh for the same user does not reload', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei]);
      makeController(source);
      await pumpEventQueue();
      final calls = source.loadCalls;

      auth.add('user-a');
      await pumpEventQueue();
      expect(source.loadCalls, calls);
    });

    test('load error shows a message, Try again works', () async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei], savedIds: ['2'])
        ..offline = true;
      final c = makeController(source);
      await pumpEventQueue();
      expect(c.state, SavedRoutesState.error);
      expect(c.errorMessage, contains('No internet'));

      source.offline = false;
      await c.refresh();
      expect(c.state, SavedRoutesState.idle);
      expect(c.isSaved('2'), isTrue);
    });
  });

  group('Widgets', () {
    // Точно по GWT из TSIS 6–7: Given I am logged in and see a trail card,
    // When I tap the heart icon, Then the trail appears in "My routes".
    testWidgets('US-10 GWT: heart on the Home trail card saves the trail',
        (tester) async {
      userId = 'user-a';
      final source = FakeSavedRoutes([_karakungei]);
      final c = makeController(source);
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          repository: FakeTrails([_karakungei]),
          savedRoutes: c,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trail_card_karakungei')), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_route_button')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(source.savedIds, ['2']);
      expect(c.routes.map((r) => r.title), ['Karakungei']);
    });

    testWidgets('heart icon fills after tap', (tester) async {
      userId = 'user-a';
      final c = makeController(FakeSavedRoutes([_karakungei]));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [SaveRouteButton(route: _karakungei, controller: c)],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save_route_button')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.textContaining('Route saved'), findsOneWidget);
    });

    testWidgets('My routes section: empty state, then a saved route',
        (tester) async {
      userId = 'user-a';
      final c = makeController(FakeSavedRoutes([_karakungei]));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SavedRoutesSection(controller: c)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('saved_routes_empty')), findsOneWidget);

      await c.toggle(_karakungei);
      await tester.pumpAndSettle();
      expect(find.text('Karakungei'), findsOneWidget);
      expect(find.byKey(const ValueKey('saved_routes_count')), findsOneWidget);
    });
  });
}
