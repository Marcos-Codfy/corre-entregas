import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';

import 'sections/foundation_sections.dart';
import 'sections/component_sections.dart';
import 'sections/domain_sections.dart';

void main() => runApp(const DsSampleApp());

/// Catálogo vivo do design system do Corre.
class DsSampleApp extends StatefulWidget {
  const DsSampleApp({super.key, this.useGoogleFonts = true});
  final bool useGoogleFonts;

  @override
  State<DsSampleApp> createState() => _DsSampleAppState();
}

class _DsSampleAppState extends State<DsSampleApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Corre · Design System',
        debugShowCheckedModeBanner: false,
        theme: CorreTheme.light(useGoogleFonts: widget.useGoogleFonts),
        darkTheme: CorreTheme.dark(useGoogleFonts: widget.useGoogleFonts),
        themeMode: _mode,
        home: CatalogPage(
          dark: _mode == ThemeMode.dark,
          onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
        ),
      );
}

class CatalogSection {
  const CatalogSection(this.item, this.builder);
  final CorreNavItem item;
  final WidgetBuilder builder;
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key, required this.dark, required this.onToggleTheme});
  final bool dark;
  final VoidCallback onToggleTheme;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  int _index = 0;

  static final sections = <CatalogSection>[
    CatalogSection(const CorreNavItem(label: 'Visão geral', icon: Icons.auto_awesome_outlined), (_) => const OverviewSection()),
    CatalogSection(const CorreNavItem(label: 'Cores', icon: Icons.palette_outlined), (_) => const ColorsSection()),
    CatalogSection(const CorreNavItem(label: 'Tipografia', icon: Icons.text_fields), (_) => const TypographySection()),
    CatalogSection(const CorreNavItem(label: 'Espaços e raios', icon: Icons.space_bar), (_) => const SpacingSection()),
    CatalogSection(const CorreNavItem(label: 'Botões', icon: Icons.smart_button_outlined), (_) => const ButtonsSection()),
    CatalogSection(const CorreNavItem(label: 'Campos', icon: Icons.edit_outlined), (_) => const InputsSection()),
    CatalogSection(const CorreNavItem(label: 'Seleção', icon: Icons.toggle_on_outlined), (_) => const SelectionSection()),
    CatalogSection(const CorreNavItem(label: 'Exibição', icon: Icons.view_agenda_outlined), (_) => const DisplaySection()),
    CatalogSection(const CorreNavItem(label: 'Feedback', icon: Icons.notifications_none), (_) => const FeedbackSection()),
    CatalogSection(const CorreNavItem(label: 'Entregas', icon: Icons.two_wheeler), (_) => const DomainSection()),
    CatalogSection(const CorreNavItem(label: 'Layout', icon: Icons.dashboard_outlined), (_) => const LayoutSection()),
  ];

  @override
  Widget build(BuildContext context) => CorreWebShell(
        sectionLabel: 'design system',
        items: [for (final s in sections) s.item],
        index: _index,
        onTap: (i) => setState(() => _index = i),
        headerTrailing: IconButton(
          tooltip: widget.dark ? 'Tema claro' : 'Tema escuro',
          icon: Icon(widget.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onPressed: widget.onToggleTheme,
        ),
        body: KeyedSubtree(key: ValueKey(_index), child: sections[_index].builder(context)),
      );
}

/// Bloco de demonstração com título e descrição.
class DemoBlock extends StatelessWidget {
  const DemoBlock({super.key, required this.title, this.description, required this.child});
  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: CorreSpace.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: context.text.titleLarge),
          if (description != null) ...[
            const SizedBox(height: CorreSpace.xs),
            Text(description!, style: context.text.bodyMedium),
          ],
          const SizedBox(height: CorreSpace.md),
          child,
        ]),
      );
}
