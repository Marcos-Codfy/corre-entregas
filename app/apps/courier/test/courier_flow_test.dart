import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:courier/app/courier_app.dart';
import 'package:courier/features/auth/signup_page.dart';
import 'package:courier/features/offline/offline_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(Widget, DemoEnvironment, ProviderContainer)> _app(WidgetTester tester, {String? role}) async {
  CorreMapView.showTiles = false;
  SharedPreferences.setMockInitialValues({'demo_role': ?role});
  final prefs = await SharedPreferences.getInstance();
  final env = (await tester.runAsync(() => DemoEnvironment.seeded(withHistory: false)))!;
  final container = ProviderContainer(overrides: [
    environmentProvider.overrideWithValue(env),
    preferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(() {
    env.dispose();
    container.dispose();
  });
  return (UncontrolledProviderScope(container: container, child: const CourierApp(useGoogleFonts: false)), env, container);
}

/// Os repositórios do teste vivem fora da zona falsa: alterna tempo real e quadros.
Future<void> settle(WidgetTester tester, [int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() {
    // Celular padrão.
  });

  testWidgets('sem sessão abre o login; e-mail inválido mostra erro e não entra', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, _, container) = await _app(tester);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'sem-arroba');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(container.read(sessionProvider), isNull);
  });

  testWidgets('fluxo completo: online → oferta → aceitar → etapas → código errado → código certo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, env, _) = await _app(tester, role: 'courier');
    await tester.pumpWidget(app);
    await settle(tester);
    expect(find.textContaining('Olá, Diego'), findsOneWidget);

    // Pede uma oferta direto (fica online sozinho).
    await tester.tap(find.text('Simular nova corrida'));
    await settle(tester);
    expect(find.text('Aceitar corrida'), findsOneWidget);
    final offered = env.deliveries.all().first;
    expect(offered.status, DeliveryStatus.searching);

    await tester.tap(find.text('Aceitar corrida'));
    await settle(tester);
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.accepted);
    expect(find.text('Cheguei no comércio'), findsOneWidget);

    Future<void> tapAction(String label) async {
      await tester.tap(find.text('Pular deslocamento (demonstração)'));
      await settle(tester);
      await tester.tap(find.text(label));
      await settle(tester);
    }

    await tapAction('Cheguei no comércio');
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.atMerchant);
    await tester.tap(find.text('Coletei o pedido'));
    await settle(tester);
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.toCustomer);
    await tapAction('Cheguei no cliente');
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.atCustomer);

    await tester.tap(find.text('Confirmar com o código'));
    await settle(tester);
    final code = env.deliveries.byId(offered.id)!.deliveryCode;
    final wrong = code == '9999' ? '1111' : '9999';
    await tester.enterText(find.byKey(const Key('code-input')), wrong);
    await settle(tester);
    expect(find.textContaining('Código não confere'), findsOneWidget);
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.atCustomer);

    final before = env.wallet.balanceOf(Seed.demoCourierId);
    await tester.enterText(find.byKey(const Key('code-input')), code);
    await settle(tester);
    expect(env.deliveries.byId(offered.id)!.status, DeliveryStatus.delivered);
    expect(env.wallet.balanceOf(Seed.demoCourierId), before + offered.courierAmount);

    env.dispose();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('recusar oferta não pune e a corrida segue procurando outro motoboy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final (app, env, _) = await _app(tester, role: 'courier');
    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.text('Simular nova corrida'));
    await settle(tester);
    final ratingBefore = env.couriers.byId(Seed.demoCourierId)!.rating;
    await tester.tap(find.text('Recusar'));
    await settle(tester);
    expect(find.text('Aceitar corrida'), findsNothing);
    expect(env.couriers.byId(Seed.demoCourierId)!.rating, ratingBefore);
    expect(env.events.all().any((e) => e.type == 'offer.declined'), isTrue);
    env.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  test('fila offline guarda ações e executa na ordem quando volta', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final q = c.read(offlineQueueProvider.notifier);
    final done = <int>[];
    await q.setOnline(false);
    await q.run('a', () async => done.add(1));
    await q.run('b', () async => done.add(2));
    expect(done, isEmpty);
    expect(c.read(offlineQueueProvider).pending, hasLength(2));
    await q.setOnline(true);
    expect(done, [1, 2]);
    expect(c.read(offlineQueueProvider).pending, isEmpty);
  });

  group('regras de cadastro', () {
    test('idade mínima de 18 anos', () {
      expect(SignupRules.validateBirthYear('2008', currentYear: 2026), isNull);
      expect(SignupRules.validateBirthYear('2009', currentYear: 2026), isNotNull);
      expect(SignupRules.validateBirthYear('abc', currentYear: 2026), isNotNull);
      expect(SignupRules.validateBirthYear('1800', currentYear: 2026), isNotNull);
    });

    test('CPF com dígito verificador', () {
      expect(SignupRules.validateCpf('529.982.247-25'), isNull);
      expect(SignupRules.validateCpf('529.982.247-24'), isNotNull);
      expect(SignupRules.validateCpf('111.111.111-11'), isNotNull, reason: 'repetidos');
      expect(SignupRules.validateCpf('123'), isNotNull);
    });
  });
}
