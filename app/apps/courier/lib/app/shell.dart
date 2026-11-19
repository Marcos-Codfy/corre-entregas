import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/courier_controller.dart';
import '../features/home/offer_sheet.dart';
import '../features/offline/offline_queue.dart';

/// Estrutura com navegação inferior. Mostra a oferta por cima de qualquer aba.
class CourierShell extends ConsumerWidget {
  const CourierShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(courierControllerProvider.select((s) => s.offer));
    final offline = ref.watch(offlineQueueProvider);
    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
              if (!offline.online)
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(CorreSpace.md, CorreSpace.sm, CorreSpace.md, 0),
                    child: CorreBanner(
                      tone: CorreTone.warning,
                      icon: Icons.wifi_off,
                      message: offline.pending.isEmpty
                          ? 'Sem internet. Suas ações ficam salvas no aparelho.'
                          : 'Sem internet. ${offline.pending.length} ação(ões) aguardando envio.',
                    ),
                  ),
                ),
              Expanded(child: shell),
            ],
          ),
          bottomNavigationBar: CorreBottomNav(
            index: shell.currentIndex,
            onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            items: const [
              CorreNavItem(label: 'Início', icon: Icons.home_outlined, selectedIcon: Icons.home),
              CorreNavItem(label: 'Corridas', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long),
              CorreNavItem(
                label: 'Carteira',
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
              ),
              CorreNavItem(label: 'Perfil', icon: Icons.person_outline, selectedIcon: Icons.person),
            ],
          ),
        ),
        if (offer != null) OfferOverlay(offer: offer),
      ],
    );
  }
}
