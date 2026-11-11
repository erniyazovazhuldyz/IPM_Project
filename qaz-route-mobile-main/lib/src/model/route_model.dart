import 'package:latlong2/latlong.dart';

final class RouteModel {
  const RouteModel({
    required this.id,
    required this.previewImageUrl,
    required this.routeImagesUrls,
    required this.title,
    required this.location,
    required this.path,
    required this.completionTime,
    required this.distance,
    required this.description,
    this.slug,
    this.city,
    this.difficulty,
    this.elevationGainM,
    this.maxElevationM,
    this.isVerified = false,
  });

  final String id;
  final String? slug;
  final String previewImageUrl;
  final List<String> routeImagesUrls;
  final String title;
  final String? city;
  final String location;

  /// Minutes.
  final int completionTime;

  /// Kilometres (may have decimals, e.g. 1.5).
  final double distance;
  final List<LatLng> path;
  final String description;
  final String? difficulty;
  final int? elevationGainM;
  final int? maxElevationM;
  final bool isVerified;

  /// City shown on cards; falls back to [location] for old rows.
  String get displayCity =>
      (city != null && city!.trim().isNotEmpty) ? city! : location;

  String formattedDistance() {
    final text = distance == distance.roundToDouble()
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return '$text km';
  }

  String formattedCompletionTime() {
    if (completionTime < 60) {
      return '$completionTime min';
    } else {
      final hours = completionTime ~/ 60;
      final mins = completionTime % 60;
      return mins > 0 ? '$hours h $mins min' : '$hours h';
    }
  }

  /// "easy" -> "Easy"
  String? formattedDifficulty() {
    final d = difficulty?.trim();
    if (d == null || d.isEmpty) return null;
    return d[0].toUpperCase() + d.substring(1).toLowerCase();
  }

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'].toString(),
      slug: map['slug'] as String?,
      previewImageUrl: map['preview_image_url'] as String,
      routeImagesUrls: List<String>.from(map['route_images_urls'] ?? const []),
      title: map['title'] as String,
      city: map['city'] as String?,
      location: (map['location'] as String?) ?? '',
      completionTime: (map['completion_time'] as num).toInt(),
      distance: (map['distance'] as num).toDouble(),
      path: List<LatLng>.from(
        ((map['path'] as List?) ?? const []).map((latLng) {
          final coords = (latLng as String).split(',');
          return LatLng(
            double.parse(coords[0].trim()),
            double.parse(coords[1].trim()),
          );
        }),
      ),
      description: (map['description'] as String?) ?? '',
      difficulty: map['difficulty'] as String?,
      elevationGainM: (map['elevation_gain_m'] as num?)?.toInt(),
      maxElevationM: (map['max_elevation_m'] as num?)?.toInt(),
      isVerified: (map['is_verified'] as bool?) ?? false,
    );
  }
}
