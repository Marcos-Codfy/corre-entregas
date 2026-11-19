import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:courier/app/courier_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester tester, [int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  const sizes = {
    'celular pequeno': Size(360, 690),
    'tablet em pé': Size(800, 1280),
    'tablet deitado': Size(1280, 800),
  };

  for (final e in sizes.entries) {
    testWidgets('início, oferta, corrida e abas abrem sem estourar: ${e.key}', (tester) async {
      CorreMapView.showTiles = false;
      tester.view.physicalSize = e.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'demo_role': 'courier'});
      final prefs = await SharedPreferences.getInstance();
      final env = (await tester.runAsync(() => DemoEnvironment.seeded()))!;
      final c = ProviderContainer(overrides: [environmentProvider.overrideWithValue(env), preferencesProvider.overrideWithValue(prefs)]);
      addTearDown(() {
        env.dispose();
        c.dispose();
      });
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const CourierApp(useGoogleFonts: false)));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('R\$ 0,00'), findsNothing, reason: 'demonstração abre com corridas de hoje');

      await tester.tap(find.text('Simular nova corrida'));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'oferta');
      await tester.ensureVisible(find.text('Aceitar corrida'));
      await tester.pump();
      await tester.tap(find.text('Aceitar corrida'));
      await settle(tester);
      expect(find.text('Cheguei no comércio'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'corrida');

      Navigator.of(tester.element(find.text('Cheguei no comércio'))).pop();
      await settle(tester, 2);
      for (final tab in ['Corridas', 'Carteira', 'Perfil']) {
        await tester.tap(find.text(tab).last);
        await settle(tester, 2);
        expect(tester.takeException(), isNull, reason: tab);
      }
      env.dispose();
      await tester.pump(const Duration(seconds: 2));
    });
  }
}
