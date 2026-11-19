import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel/app/panel_app.dart';
import 'package:panel/app/router.dart';
import 'package:panel/app/session.dart';
import 'package:panel/features/backoffice/pricing_coupons_pages.dart';
import 'package:panel/features/merchant/deliveries_page.dart';
import 'package:panel/features/merchant/new_delivery_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Os repositórios vivem fora da zona falsa do teste: alterna tempo real e quadros.
Future<void> settle(WidgetTester tester, [int rounds = 4]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<(DemoEnvironment, ProviderContainer)> pumpPanel(WidgetTester tester, {String? role, Size size = const Size(1440, 1000)}) async {
  CorreMapView.showTiles = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'demo_role': ?role});
  final prefs = await SharedPreferences.getInstance();
  final env = (await tester.runAsync(() => DemoEnvironment.seeded(withHistory: false, timeScale: 1000)))!;
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
  group('permissões por perfil', () {
    test('atendente não vê financeiro nem equipe; admin vê preços e cupons', () {
      final staff = navFor(DemoRole.merchantStaff).map((n) => n.label);
      expect(staff, isNot(contains('Carteira e plano')));
      expect(staff, isNot(contains('Equipe')));
      final owner = navFor(DemoRole.merchantOwner).map((n) => n.label);
      expect(owner, containsAll(['Carteira e plano', 'Equipe']));
      final support = navFor(DemoRole.support).map((n) => n.label);
      expect(support, isNot(contains('Preços')));
      expect(support, contains('Ao vivo'));
      expect(navFor(DemoRole.admin).map((n) => n.label), containsAll(['Indicadores', 'Preços', 'Cupons', 'Repasses', 'Eventos']));
    });

    test('todo perfil do painel tem a rota inicial "/"', () {
      for (final r in [DemoRole.merchantOwner, DemoRole.merchantStaff, DemoRole.support, DemoRole.admin]) {
        expect(navFor(r).map((n) => n.path), contains('/'), reason: r.name);
      }
    });
  });

  group('funções de apoio', () {
    test('busca de endereço precisa de 2 letras e ignora maiúsculas', () {
      expect(searchAddresses('2'), isEmpty);
      expect(searchAddresses('208 sul').single.line, contains('208 Sul'));
      expect(searchAddresses('TAQUARALTO'), isNotEmpty);
      expect(searchAddresses('xyzxyz'), isEmpty);
    });

    test('parseCents aceita valor formatado e rejeita vazio', () {
      expect(parseCents('R\$ 8,00'), 800);
      expect(parseCents('1,50'), 150);
      expect(parseCents(''), isNull);
    });

    test('CSV não leva nome nem telefone do cliente e escapa ponto e vírgula', () {
      final hist = Seed.history(now: DateTime(2026, 11, 19)).take(3).toList();
      const named = Customer(name: 'Mariana Silva', phone: '63988881234');
      final withCustomer = [hist.first.copyWith(customer: named), ...hist.skip(1)];
      final csv = deliveriesCsv(withCustomer, {});
      expect(csv.split('\n').first, startsWith('codigo;'));
      expect(csv, isNot(contains('Mariana')));
      expect(csv, isNot(contains('63988881234')));
      expect(csv.trim().split('\n'), hasLength(4));
    });
  });

  testWidgets('sem sessão vai para o login; rastreio público abre sem login', (tester) async {
    final (env, c) = await pumpPanel(tester);
    expect(find.text('Entrar como (demonstração)'), findsOneWidget);
    c.read(routerProvider).go('/r/token-que-nao-existe');
    await settle(tester);
    expect(find.text('Link de rastreio inválido'), findsOneWidget);
    env.dispose();
  });

  testWidgets('comércio pede entrega: valida campos, reserva saldo e mostra o código', (tester) async {
    final (env, c) = await pumpPanel(tester, role: 'merchantOwner');
    expect(find.text('Boa noite, Burger da 106'), findsOneWidget);
    c.read(routerProvider).go('/nova');
    await settle(tester);

    await tester.tap(find.text('Chamar motoboy'));
    await settle(tester, 2);
    expect(find.text('Informe o nome do cliente'), findsOneWidget);
    expect(find.text('Escolha o endereço na busca ou toque no mapa'), findsOneWidget);
    expect(env.deliveries.all(), isEmpty);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '208');
    await settle(tester, 2);
    await tester.tap(find.text('Qd. 208 Sul, Al. 12, lote 7').first);
    await settle(tester, 2);
    await tester.enterText(fields.at(2), 'Mariana Silva');
    await tester.enterText(fields.at(3), '63988881234');
    await settle(tester, 2);
    final balance = env.merchants.byId(Seed.demoMerchantId)!.balance;
    await tester.tap(find.text('Chamar motoboy'));
    await settle(tester, 6);

    final d = env.deliveries.all().single;
    expect(env.merchants.byId(Seed.demoMerchantId)!.balance, balance - d.merchantTotal);
    expect(find.text('Código de entrega do cliente'), findsOneWidget);
    expect(find.text(d.deliveryCode), findsOneWidget);
    expect(find.text('Enviar pelo WhatsApp'), findsOneWidget);
    env.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('cupom inválido mostra erro; cupom válido vira entregas sem taxa', (tester) async {
    final (env, c) = await pumpPanel(tester, role: 'merchantOwner');
    c.read(routerProvider).go('/carteira');
    await settle(tester);
    final couponField = find.widgetWithText(TextFormField, '').first;
    await tester.enterText(find.byType(TextFormField).first, 'TAXA050');
    await tester.tap(find.text('Aplicar'));
    await settle(tester, 2);
    expect(find.textContaining('vencido'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'BEMVINDO10');
    await tester.tap(find.text('Aplicar'));
    await settle(tester, 2);
    expect(find.text('10 entregas sem taxa'), findsOneWidget);
    expect(env.coupons.byCode('BEMVINDO10')!.used, 8);
    expect(couponField, findsWidgets);
    env.dispose();
  });

  testWidgets('admin abre indicadores e o suporte ao vivo sem erro', (tester) async {
    final (env, c) = await pumpPanel(tester, role: 'admin');
    expect(find.text('Indicadores'), findsWidgets);
    for (final path in ['/ao-vivo', '/ocorrencias', '/cadastros', '/precos', '/cupons', '/repasses', '/eventos', '/comercios', '/motoboys']) {
      c.read(routerProvider).go(path);
      await settle(tester, 2);
      expect(tester.takeException(), isNull, reason: path);
    }
    env.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('aprovar motoboy exige documentos conferidos', (tester) async {
    final (env, c) = await pumpPanel(tester, role: 'support');
    c.read(routerProvider).go('/cadastros');
    await settle(tester);
    await tester.tap(find.text('Aprovar').first);
    await settle(tester, 2);
    expect(find.text('Confira todos os documentos antes de aprovar'), findsOneWidget);
    expect(env.couriers.all().where((x) => x.approval == ApprovalStatus.pending), hasLength(2));
    env.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('layout de celular abre com gaveta sem estourar', (tester) async {
    final (env, _) = await pumpPanel(tester, role: 'merchantOwner', size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.text('Pedir entregador'), findsOneWidget);
    env.dispose();
  });

  test('perfil de comércio usa o comércio de demonstração', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(myMerchantIdProvider), Seed.demoMerchantId);
  });
}
