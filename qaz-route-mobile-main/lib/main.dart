import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qaz_route_mobile/src/core/supabase_config.dart';
import 'package:qaz_route_mobile/src/widget/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint(
    'Supabase: ${SupabaseConfig.url}'
    '${SupabaseConfig.isOldProject ? ' (OLD project)' : ''}',
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: kDebugMode,
  );

  runApp(const App());
}
