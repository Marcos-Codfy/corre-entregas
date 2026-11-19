import 'package:flutter/material.dart';

import '../theme/corre_theme.dart';
import '../tokens/corre_tokens.dart';
import 'corre_domain.dart';

/// Item de navegação usado no app e no painel.
class CorreNavItem {
  const CorreNavItem({required this.label, required this.icon, this.selectedIcon});
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Tamanho de tela atual.
enum CorreScreenSize { mobile, tablet, desktop }

extension CorreScreenX on BuildContext {
  CorreScreenSize get screenSize {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= CorreBreakpoint.desktop) return CorreScreenSize.desktop;
    if (w >= CorreBreakpoint.tablet) return CorreScreenSize.tablet;
    return CorreScreenSize.mobile;
  }
}

/// Barra de navegação inferior (app mobile).
class CorreBottomNav extends StatelessWidget {
  const CorreBottomNav({super.key, required this.items, required this.index, required this.onTap});
  final List<CorreNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        destinations: [
          for (final i in items)
            NavigationDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon ?? i.icon), label: i.label),
        ],
      );
}

/// Estrutura do painel web: menu lateral fixo no desktop, trilho no tablet e gaveta no celular.
class CorreWebShell extends StatelessWidget {
  const CorreWebShell({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    required this.body,
    this.title,
    this.headerTrailing,
    this.sectionLabel,
  });

  final List<CorreNavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final Widget body;
  final String? title;
  final Widget? headerTrailing;

  /// Ex.: "Comércio" ou "Suporte".
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    final size = context.screenSize;
    final p = context.palette;

    Widget menu({required bool expanded}) => Container(
          width: expanded ? 248 : 80,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(right: BorderSide(color: p.line))),
          child: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.all(CorreSpace.lg),
                child: expanded ? CorreLogo(size: 26, subtitle: sectionLabel) : const Center(child: CorreLogo(size: 18)),
              ),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CorreSpace.sm, vertical: 2),
                  child: Material(
                    color: i == index ? p.brandLight : Colors.transparent,
                    borderRadius: CorreRadius.mdAll,
                    child: InkWell(
                      borderRadius: CorreRadius.mdAll,
                      onTap: () {
                        if (size == CorreScreenSize.mobile) Navigator.of(context).maybePop();
                        onTap(i);
                      },
                      child: Tooltip(
                        message: expanded ? '' : items[i].label,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: CorreSpace.md, vertical: CorreSpace.md),
                          child: Row(
                            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                            children: [
                              Icon(i == index ? (items[i].selectedIcon ?? items[i].icon) : items[i].icon,
                                  color: i == index ? p.brand : p.ink2, size: 22),
                              if (expanded) ...[
                                const SizedBox(width: CorreSpace.md),
                                Expanded(
                                  child: Text(items[i].label,
                                      style: context.text.titleSmall?.copyWith(color: i == index ? p.brand : p.ink2)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        );

    final header = AppBar(
      automaticallyImplyLeading: size == CorreScreenSize.mobile,
      title: Text(title ?? items[index].label),
      actions: [?headerTrailing, const SizedBox(width: CorreSpace.sm)],
    );

    if (size == CorreScreenSize.mobile) {
      return Scaffold(appBar: header, drawer: Drawer(child: menu(expanded: true)), body: body);
    }
    return Scaffold(
      body: Row(children: [
        menu(expanded: size == CorreScreenSize.desktop),
        Expanded(child: Scaffold(appBar: header, body: body)),
      ]),
    );
  }
}

/// Conteúdo com largura máxima e margens padrão.
class CorrePage extends StatelessWidget {
  const CorrePage({super.key, required this.children, this.maxWidth = 1200, this.padding});
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: padding ?? const EdgeInsets.all(CorreSpace.lg),
            children: children,
          ),
        ),
      );
}

/// Grade responsiva: 1 coluna no celular, [tabletColumns]/[desktopColumns] nas maiores.
class CorreResponsiveGrid extends StatelessWidget {
  const CorreResponsiveGrid({super.key, required this.children, this.tabletColumns = 2, this.desktopColumns = 4, this.spacing = CorreSpace.md});
  final List<Widget> children;
  final int tabletColumns, desktopColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final cols = switch (context.screenSize) {
      CorreScreenSize.mobile => children.length > 1 ? 2 : 1,
      CorreScreenSize.tablet => tabletColumns,
      CorreScreenSize.desktop => desktopColumns,
    };
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(spacing: spacing, runSpacing: spacing, children: [
        for (final child in children) SizedBox(width: w, child: child),
      ]);
    });
  }
}
