import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel/app/panel_app.dart';
import 'package:panel/app/router.dart';
import 'package:panel/features/merchant/merchant_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> settle(WidgetTester tester, [int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<(DemoEnvironment, ProviderContainer)> pumpPanel(WidgetTester tester, String role, Size size) async {
  CorreMapView.showTiles = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'demo_role': role});
  final prefs = await SharedPreferences.getInstance();
  final env = (await tester.runAsync(() => DemoEnvironment.seeded(timeScale: 1000)))!;
  final c = ProviderContainer(overrides: [environmentProvider.overrideWithValue(env), preferencesProvider.overrideWithValue(prefs)]);
  addTearDown(() {
    env.dispose();
    c.dispose();
  });
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const PanelApp(useGoogleFonts: false)));
  await settle(tester);
  return (env, c);
}

void main() {
  const sizes = {'celular': Size(375, 812), 'tablet em pé': Size(800, 1280), 'tablet deitado': Size(1280, 800)};

  for (final e in sizes.entries) {
    testWidgets('telas do comércio e do admin cabem: ${e.key}', (tester) async {
      final (env, c) = await pumpPanel(tester, 'merchantOwner', e.value);
      for (final path in ['/', '/nova', '/entregas', '/carteira', '/preferidos', '/config']) {
        c.read(routerProvider).go(path);
        await settle(tester, 2);
        expect(tester.takeException(), isNull, reason: '$path em ${e.key}');
      }
      c.read(sessionProvider.notifier).signIn(DemoRole.admin);
      for (final path in ['/', '/ao-vivo', '/precos', '/cupons', '/eventos']) {
        c.read(routerProvider).go(path);
        await settle(tester, 2);
        expect(tester.takeException(), isNull, reason: 'admin $path em ${e.key}');
      }
      env.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('repetir pedido: exige confirmar endereço; "mudou de endereço" não cria entrega', (tester) async {
    final (env, c) = await pumpPanel(tester, 'merchantOwner', const Size(1440, 1000));
    c.read(routerProvider).go('/nova');
    await settle(tester);
    final before = env.deliveries.all().length;

    await tester.tap(find.textContaining('Mariana ·'));
    await settle(tester, 2);
    expect(find.textContaining('o endereço do pedido de hoje é este mesmo?'), findsOneWidget);
    await tester.tap(find.text('Mudou de endereço'));
    await settle(tester, 2);
    expect(env.deliveries.all().length, before);
    expect(find.text('Busque o endereço novo do cliente'), findsOneWidget);

    await tester.tap(find.textContaining('Mariana ·'));
    await settle(tester, 2);
    await tester.tap(find.text('Endereço confere, chamar motoboy'));
    await settle(tester, 6);
    expect(env.deliveries.all().length, before + 1);
    expect(find.text('Código de entrega do cliente'), findsOneWidget);
    env.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  group('economia vs. iFood', () {
    Delivery d(int? orderValue) => Seed.history(now: DateTime(2026, 11, 19)).first.copyWith().let((x) => Delivery(
          id: 'x',
          code: 'x',
          merchantId: 'm',
          customer: x.customer,
          pickup: x.pickup,
          dropoff: x.dropoff,
          quote: const PricingService().quote(4),
          deliveryCode: '0000',
          trackingToken: 't',
          createdAt: DateTime(2026, 11, 19),
          status: DeliveryStatus.delivered,
          orderValue: orderValue,
        ));

    test('pedido de R\$ 50: iFood ~R\$ 13,10 contra R\$ 9,50 aqui', () {
      final r = SavingsReport.from([d(5000)]);
      expect(r.ifood, 1310);
      expect(r.paid, 950);
      expect(r.saved, 360);
    });

    test('sem valor informado usa R\$ 50 de referência', () {
      expect(SavingsReport.from([d(null)]).ifood, 1310);
    });

    test('pedido barato: economia nunca fica negativa', () {
      expect(SavingsReport.from([d(1000)]).saved, 0);
    });

    test('lista vazia', () => expect(SavingsReport.from(const []).saved, 0));
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
