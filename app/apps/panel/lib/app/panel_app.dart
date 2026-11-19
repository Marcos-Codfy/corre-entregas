import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

class PanelApp extends ConsumerWidget {
  const PanelApp({super.key, this.useGoogleFonts = true});
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Corre · Painel',
        debugShowCheckedModeBanner: false,
        theme: CorreTheme.light(useGoogleFonts: useGoogleFonts),
        darkTheme: CorreTheme.dark(useGoogleFonts: useGoogleFonts),
        themeMode: ref.watch(themeModeProvider),
        routerConfig: ref.watch(routerProvider),
      );
}
