import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../home/courier_controller.dart';
import '../offline/offline_queue.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final offline = ref.watch(offlineQueueProvider);
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    if (me == null) return const SizedBox.shrink();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          Row(
            children: [
              CorreAvatar(name: me.name, size: 64),
              const SizedBox(width: CorreSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.name, style: context.text.titleLarge),
                    Text('${me.bikeModel} · ${me.ratingCount} avaliações', style: context.text.bodySmall),
                    const SizedBox(height: CorreSpace.xs),
                    CorreBadge(
                      label: me.approval.label,
                      tone: me.approval == ApprovalStatus.approved ? CorreTone.success : CorreTone.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const CorreSectionHeader(title: 'Documentos'),
          CorreCard(
            child: Column(
              children: [
                for (final k in DocumentKind.values)
                  CorreListItem(
                    title: k.label,
                    trailing: CorreBadge(
                      label: (me.documents[k] ?? ApprovalStatus.pending).label,
                      tone: me.documents[k] == ApprovalStatus.approved ? CorreTone.success : CorreTone.warning,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: CorreSpace.sm),
          const CorreBanner(
            tone: CorreTone.error,
            icon: Icons.badge_outlined,
            message: 'Sua CNH vence em 20 dias. Envie a nova para continuar recebendo corridas.',
            actionLabel: 'Enviar',
          ),
          const CorreSectionHeader(title: 'Conta'),
          CorreCard(
            child: Column(
              children: [
                CorreListItem(
                  leading: const Icon(Icons.rule),
                  title: 'Nota e regras',
                  subtitle: 'Tabela de frete, nota mínima e adicionais',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.rules),
                ),
                const Divider(),
                CorreListItem(
                  leading: const Icon(Icons.support_agent),
                  title: 'Ajuda e suporte',
                  subtitle: 'Fale com o suporte local',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.help),
                ),
                const Divider(),
                CorreSwitchTile(
                  title: 'Tema escuro',
                  value: dark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const CorreSectionHeader(title: 'Demonstração'),
          CorreCard(
            child: Column(
              children: [
                CorreSwitchTile(
                  title: 'Simular sem internet',
                  subtitle: 'As ações ficam na fila e são enviadas quando a conexão volta',
                  value: !offline.online,
                  onChanged: (v) => ref.read(offlineQueueProvider.notifier).setOnline(!v),
                ),
              ],
            ),
          ),
          const SizedBox(height: CorreSpace.xl),
          CorreButton(
            label: 'Sair',
            variant: CorreButtonVariant.danger,
            onPressed: () async {
              await ref.read(courierControllerProvider.notifier).setOnline(false);
              ref.read(sessionProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: CorreSpace.md),
          Text('Corre · versão de demonstração 0.1', style: context.text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
