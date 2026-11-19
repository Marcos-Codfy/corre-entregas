import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
      theme: CorreTheme.light(useGoogleFonts: false),
      darkTheme: CorreTheme.dark(useGoogleFonts: false),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('formatBrl', () {
    test('formata milhar, centavos e negativo', () {
      expect(formatBrl(0), 'R\$ 0,00');
      expect(formatBrl(9.5), 'R\$ 9,50');
      expect(formatBrl(1234.5), 'R\$ 1.234,50');
      expect(formatBrl(1000000), 'R\$ 1.000.000,00');
      expect(formatBrl(-3), '−R\$ 3,00');
    });

    test('arredonda para 2 casas', () {
      expect(formatBrl(8.005), anyOf('R\$ 8,01', 'R\$ 8,00'));
      expect(formatBrl(0.1 + 0.2), 'R\$ 0,30');
    });
  });

  group('formatPhone', () {
    test('celular com 11 dígitos', () => expect(formatPhone('63999990000'), '(63) 9 9999-0000'));
    test('fixo com 10 dígitos', () => expect(formatPhone('6332150000'), '(63) 3215-0000'));
    test('ignora letras e corta excesso', () => expect(formatPhone('a63-99999-00001234'), '(63) 9 9999-0000'));
    test('entrada vazia', () => expect(formatPhone(''), ''));
  });

  group('CorreAvatar.initials', () {
    test('nome composto usa primeira e última', () => expect(CorreAvatar.initials('Diego da Silva Martins'), 'DM'));
    test('nome único usa uma letra', () => expect(CorreAvatar.initials('rafa'), 'R'));
    test('vazio vira interrogação', () => expect(CorreAvatar.initials('   '), '?'));
  });

  testWidgets('CorreButton chama onPressed e bloqueia durante loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(CorreButton(label: 'Aceitar', onPressed: () => taps++)));
    await tester.tap(find.text('Aceitar'));
    expect(taps, 1);

    await tester.pumpWidget(_wrap(CorreButton(label: 'Aceitar', loading: true, onPressed: () => taps++)));
    await tester.tap(find.byType(CorreButton));
    expect(taps, 1, reason: 'não pode disparar enquanto carrega');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CorreButton sem onPressed não quebra ao tocar', (tester) async {
    await tester.pumpWidget(_wrap(const CorreButton(label: 'Desabilitado')));
    await tester.tap(find.text('Desabilitado'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('CorreCodeInput só completa com 4 dígitos e ignora letras', (tester) async {
    String? done;
    await tester.pumpWidget(_wrap(CorreCodeInput(onCompleted: (v) => done = v)));
    final field = find.byKey(const Key('code-input'));
    await tester.enterText(field, '73');
    expect(done, isNull);
    await tester.enterText(field, '7a3b1');
    await tester.pump();
    expect(done, isNull, reason: 'só 3 dígitos válidos');
    await tester.enterText(field, '73161');
    await tester.pump();
    expect(done, '7316', reason: 'corta no limite de 4');
  });

  testWidgets('CorreCountdownRing avisa ao terminar e não passa de zero', (tester) async {
    var finished = 0;
    await tester.pumpWidget(_wrap(CorreCountdownRing(total: const Duration(seconds: 3), onFinished: () => finished++)));
    expect(find.text('3s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(finished, 1);
    expect(find.text('0s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(finished, 1, reason: 'dispara uma vez só');
  });

  testWidgets('CorreStepTimeline renderiza todas as etapas', (tester) async {
    await tester.pumpWidget(_wrap(const CorreStepTimeline(steps: [
      CorreStep('Aceita', CorreStepState.done),
      CorreStep('Coletada', CorreStepState.current),
      CorreStep('Entregue', CorreStepState.pending),
    ])));
    expect(find.text('Aceita'), findsOneWidget);
    expect(find.text('Entregue'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('componentes leem o tema escuro sem erro', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(mainAxisSize: MainAxisSize.min, children: [
        CorreBadge(label: 'Online', tone: CorreTone.success),
        CorreKpiTile(label: 'Entregas', value: '42'),
        CorrePriceSummary(lines: [CorrePriceLine('Frete', 9.5)], total: 11),
      ]),
      dark: true,
    ));
    expect(tester.takeException(), isNull);
    final ctx = tester.element(find.byType(CorreBadge));
    expect(ctx.palette, CorrePalette.dark);
  });

  testWidgets('CorreWebShell vira gaveta no celular e menu lateral no desktop', (tester) async {
    Widget shell() => _wrap(CorreWebShell(
          items: const [CorreNavItem(label: 'Início', icon: Icons.home), CorreNavItem(label: 'Entregas', icon: Icons.list)],
          index: 0,
          onTap: (_) {},
          body: const Text('conteúdo'),
        ));

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(shell());
    expect(find.byType(Drawer), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    tester.view.physicalSize = const Size(1400, 900);
    await tester.pumpWidget(shell());
    expect(find.text('Entregas'), findsOneWidget, reason: 'menu expandido mostra rótulos');
  });
}
