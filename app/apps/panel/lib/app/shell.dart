import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'session.dart';

/// Menu lateral + topo com troca de perfil e tema.
class PanelShell extends ConsumerStatefulWidget {
  const PanelShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  ConsumerState<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends ConsumerState<PanelShell> {
  bool _trafficOn = false;

  @override
  void initState() {
    super.initState();
    // Suporte e admin veem movimento de fundo: outros comércios pedindo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = ref.read(sessionProvider);
      if (!_trafficOn && role != null && role.isBackOffice) {
        _trafficOn = true;
        ref.read(simulatorProvider).startBackgroundTraffic(exceptMerchants: {ref.read(myMerchantIdProvider)});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(sessionProvider) ?? DemoRole.merchantOwner;
    final items = navFor(role);
    final idx = items.indexWhere((n) => n.path == widget.location);
    final merchant = ref.watch(myMerchantProvider);

    return CorreWebShell(
      sectionLabel: role.isMerchant ? 'comércio' : (role == DemoRole.admin ? 'admin' : 'suporte'),
      title: idx < 0 ? 'Entrega' : null,
      index: idx < 0 ? 0 : idx,
      items: [for (final n in items) CorreNavItem(label: n.label, icon: n.icon)],
      onTap: (i) => context.go(items[i].path),
      headerTrailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (role.isMerchant && merchant != null && role.canSeeFinance)
          Padding(
            padding: const EdgeInsets.only(right: CorreSpace.sm),
            child: CorreBadge(label: 'Saldo ${formatCents(merchant.balance)}', tone: merchant.balance < 2000 ? CorreTone.warning : CorreTone.brand),
          ),
        IconButton(
          tooltip: 'Tema claro/escuro',
          icon: Icon(ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        PopupMenuButton<DemoRole?>(
          tooltip: 'Trocar perfil',
          icon: CorreAvatar(name: role.label, size: 32),
          onSelected: (r) {
            final s = ref.read(sessionProvider.notifier);
            r == null ? s.signOut() : s.signIn(r);
            context.go('/');
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text('Perfil atual: ${role.label}')),
            const PopupMenuDivider(),
            for (final r in DemoRole.values.where((r) => r != DemoRole.courier && r != role))
              PopupMenuItem(value: r, child: Text('Entrar como ${r.label.toLowerCase()}')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: null, child: Text('Sair')),
          ],
        ),
      ]),
      body: widget.child,
    );
  }
}
