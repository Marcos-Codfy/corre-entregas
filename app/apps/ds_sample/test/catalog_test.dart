import 'package:corre_design_system/corre_design_system.dart';
import 'package:ds_sample/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('todas as seções do catálogo abrem sem erro, no claro e no escuro', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const DsSampleApp(useGoogleFonts: false));
    for (final dark in [false, true]) {
      if (dark) {
        await tester.tap(find.byTooltip('Tema escuro'));
        await tester.pumpAndSettle();
      }
      for (final s in [
        'Cores', 'Tipografia', 'Espaços e raios', 'Botões', 'Campos', 'Seleção',
        'Exibição', 'Feedback', 'Entregas', 'Layout', 'Visão geral',
      ]) {
        await tester.tap(find.descendant(of: find.byType(CorreWebShell), matching: find.text(s)).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'seção $s (escuro: $dark)');
      }
    }
  });
}
