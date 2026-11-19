import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/courier_controller.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final id = ref.watch(myCourierIdProvider);
    final entries = ref.watch(walletProvider(id)).value ?? const [];
    final balance = entries.fold<Cents>(0, (s, e) => s + e.amount);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final week = entries.where((e) => e.at.isAfter(weekAgo) && e.amount > 0).toList();
    final weekFreight = week.fold<Cents>(0, (s, e) => s + e.amount);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          Text('Carteira', style: context.text.headlineSmall),
          const SizedBox(height: CorreSpace.md),
          CorreCard(
            tone: CorreTone.brand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disponível para saque', style: context.text.bodyMedium),
                Text(formatCents(balance), style: context.text.displaySmall?.copyWith(color: context.palette.brand)),
                Text('Chave Pix: CPF ${me?.pixKey ?? ''}', style: context.text.bodySmall),
                const SizedBox(height: CorreSpace.md),
                CorreButton(
                  label: 'Sacar via Pix (grátis)',
                  variant: CorreButtonVariant.accent,
                  onPressed: balance <= 0
                      ? null
                      : () async {
                          final ok = await showCorreConfirm(
                            context,
                            title: 'Sacar ${formatCents(balance)}?',
                            message: 'O Pix cai na sua chave ainda hoje, sem taxa.',
                            confirmLabel: 'Sacar',
                          );
                          if (!ok) return;
                          try {
                            await ref.read(serviceProvider).withdraw(id);
                            if (context.mounted)
                              CorreToast.show(context, 'Pix solicitado. Cai hoje até as 23h.', tone: CorreTone.success);
                          } on BusinessError catch (e) {
                            if (context.mounted) CorreToast.show(context, e.message, tone: CorreTone.error);
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: CorreSpace.md),
          CorreResponsiveGrid(
            children: [
              CorreKpiTile(
                label: 'Últimos 7 dias',
                value: formatCents(weekFreight),
                icon: Icons.calendar_today_outlined,
              ),
              CorreKpiTile(
                label: 'Entregas na semana',
                value: '${week.where((e) => e.kind == WalletEntryKind.freight).length}',
                icon: Icons.two_wheeler,
              ),
            ],
          ),
          const CorreSectionHeader(title: 'Extrato'),
          if (entries.isEmpty)
            const CorreEmptyState(icon: Icons.receipt_long_outlined, title: 'Sem lançamentos ainda')
          else
            CorreCard(
              padding: const EdgeInsets.symmetric(horizontal: CorreSpace.lg),
              child: Column(
                children: [
                  for (final e in entries.take(40)) ...[
                    CorreListItem(
                      leading: Icon(
                        e.amount >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: e.amount >= 0 ? context.palette.success : context.palette.ink2,
                      ),
                      title: e.description,
                      subtitle: '${ddmm(e.at)} · ${hhmm(e.at)}',
                      trailing: Text(
                        '${e.amount >= 0 ? '+' : ''}${formatCents(e.amount)}',
                        style: context.text.titleSmall?.copyWith(color: e.amount >= 0 ? context.palette.success : null),
                      ),
                    ),
                    if (e != entries.take(40).last) const Divider(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
