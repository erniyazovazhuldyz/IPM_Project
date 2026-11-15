import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';

/// Shared "show this trail on the map" request (US-04).
///
/// The trail screen calls [show] before opening the Map tab, and the Map tab
/// listens, draws that trail's line and moves the camera to it.
class MapFocus extends ChangeNotifier {
  MapFocus._();

  static final MapFocus instance = MapFocus._();

  RouteModel? _route;

  RouteModel? get route => _route;

  void show(RouteModel route) {
    _route = route;
    notifyListeners(); // notify even if it is the same trail again
  }
}
