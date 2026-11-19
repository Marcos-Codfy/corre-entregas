import 'package:corre_core/corre_core.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/panel_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final env = await DemoEnvironment.seeded();
  runApp(ProviderScope(
    overrides: [
      environmentProvider.overrideWithValue(env),
      preferencesProvider.overrideWithValue(prefs),
    ],
    child: const PanelApp(),
  ));
}
