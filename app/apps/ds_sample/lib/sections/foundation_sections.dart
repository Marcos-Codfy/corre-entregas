import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) => CorrePage(maxWidth: 900, children: [
        const CorreLogo(size: 44),
        const SizedBox(height: CorreSpace.md),
        Text('Design system do Corre', style: context.text.headlineMedium),
        const SizedBox(height: CorreSpace.sm),
        Text(
          'Catálogo dos tokens e componentes usados no app do motoboy e no painel web do comércio e do suporte. '
          'Tudo é feito em Flutter e vem de um único pacote, então uma mudança aqui vale para todos os apps.',
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: CorreSpace.xl),
        const CorreResponsiveGrid(desktopColumns: 3, children: [
          _Principle(icon: Icons.touch_app_outlined, title: 'Feito para a rua', text: 'Botões grandes, alto contraste e poucas ações por tela: o motoboy usa com uma mão, no sol.'),
          _Principle(icon: Icons.bolt_outlined, title: 'Rápido de entender', text: 'Status com cor e texto, valores sempre em reais e etapas da entrega à vista.'),
          _Principle(icon: Icons.dark_mode_outlined, title: 'Claro e escuro', text: 'Todos os componentes leem as cores do tema; use o botão no topo para alternar.'),
        ]),
        const SizedBox(height: CorreSpace.xl),
        const CorreBanner(message: 'Use o menu para ver cada grupo. Os componentes são interativos.', icon: Icons.menu_open),
      ]);
}

class _Principle extends StatelessWidget {
  const _Principle({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => CorreCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: context.palette.brand),
          const SizedBox(height: CorreSpace.sm),
          Text(title, style: context.text.titleMedium),
          const SizedBox(height: CorreSpace.xs),
          Text(text, style: context.text.bodyMedium),
        ]),
      );
}

class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final groups = {
      'Marca': {'brand': p.brand, 'brandLight': p.brandLight, 'accent': p.accent, 'accentLight': p.accentLight},
      'Texto e linhas': {'ink': p.ink, 'ink2': p.ink2, 'ink3': p.ink3, 'line': p.line},
      'Status': {'success': p.success, 'warning': p.warning, 'error': p.error, 'info': p.info},
    };
    return CorrePage(children: [
      for (final g in groups.entries)
        DemoBlock(
          title: g.key,
          child: CorreResponsiveGrid(children: [for (final c in g.value.entries) _Swatch(name: c.key, color: c.value)]),
        ),
      DemoBlock(
        title: 'Tons semânticos',
        description: 'Usados por badges, alertas e marcadores. Cada tom tem cor de texto e de fundo.',
        child: Wrap(spacing: CorreSpace.sm, runSpacing: CorreSpace.sm, children: [
          for (final t in CorreTone.values) CorreBadge(label: t.name, tone: t),
        ]),
      ),
    ]);
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});
  final String name;
  final Color color;

  String get hex => '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) => CorreCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 72, color: color),
          Padding(
            padding: const EdgeInsets.all(CorreSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: context.text.titleSmall),
              Text(hex, style: context.text.bodySmall),
            ]),
          ),
        ]),
      );
}

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final styles = {
      'displaySmall · 34/800': t.displaySmall,
      'headlineMedium · 26/800': t.headlineMedium,
      'headlineSmall · 22/700': t.headlineSmall,
      'titleLarge · 18/700': t.titleLarge,
      'titleMedium · 16/600': t.titleMedium,
      'titleSmall · 14/600': t.titleSmall,
      'bodyLarge · 16/400': t.bodyLarge,
      'bodyMedium · 14/400': t.bodyMedium,
      'bodySmall · 12/400': t.bodySmall,
      'labelLarge · 15/700': t.labelLarge,
      'labelMedium · 13/600': t.labelMedium,
      'labelSmall · 11/700': t.labelSmall,
    };
    return CorrePage(maxWidth: 900, children: [
      DemoBlock(
        title: 'Plus Jakarta Sans',
        description: 'Fonte única em todo o produto. Pesos de 400 a 800.',
        child: CorreCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final e in styles.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: CorreSpace.sm),
                child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  SizedBox(width: 190, child: Text(e.key, style: t.bodySmall)),
                  Expanded(child: Text('Entrega a caminho', style: e.value)),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }
}

class SpacingSection extends StatelessWidget {
  const SpacingSection({super.key});

  @override
  Widget build(BuildContext context) {
    const spaces = {'xxs': CorreSpace.xxs, 'xs': CorreSpace.xs, 'sm': CorreSpace.sm, 'md': CorreSpace.md, 'lg': CorreSpace.lg, 'xl': CorreSpace.xl, 'xxl': CorreSpace.xxl, 'xxxl': CorreSpace.xxxl};
    const radii = {'sm': CorreRadius.sm, 'md': CorreRadius.md, 'lg': CorreRadius.lg, 'pill': CorreRadius.pill};
    final p = context.palette;
    return CorrePage(maxWidth: 900, children: [
      DemoBlock(
        title: 'Espaçamentos',
        description: 'Múltiplos de 4. Use sempre os tokens, nunca números soltos.',
        child: CorreCard(
          child: Column(children: [
            for (final e in spaces.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: CorreSpace.xs),
                child: Row(children: [
                  SizedBox(width: 90, child: Text('${e.key} · ${e.value.toInt()}', style: context.text.bodySmall)),
                  Container(width: e.value * 4, height: 14, decoration: BoxDecoration(color: p.brand, borderRadius: CorreRadius.smAll)),
                ]),
              ),
          ]),
        ),
      ),
      DemoBlock(
        title: 'Raios',
        child: Wrap(spacing: CorreSpace.lg, runSpacing: CorreSpace.lg, children: [
          for (final e in radii.entries)
            Column(children: [
              Container(
                width: 88,
                height: 64,
                decoration: BoxDecoration(color: p.brandLight, border: Border.all(color: p.brand, width: 2), borderRadius: BorderRadius.circular(e.value)),
              ),
              const SizedBox(height: CorreSpace.xs),
              Text(e.key, style: context.text.bodySmall),
            ]),
        ]),
      ),
      DemoBlock(
        title: 'Sombras',
        child: Wrap(spacing: CorreSpace.xl, children: [
          for (final e in {'card': CorreShadow.card, 'raised': CorreShadow.raised}.entries)
            Container(
              width: 140,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: CorreRadius.mdAll, boxShadow: e.value),
              child: Text(e.key, style: context.text.titleSmall),
            ),
        ]),
      ),
    ]);
  }
}
