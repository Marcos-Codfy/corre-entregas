import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';

/// Créditos de entregas sem taxa ganhos com cupom (só na sessão de demonstração).
class FeeWaiverCredits extends Notifier<int> {
  @override
  int build() => 0;
  void add(int n) => state += n;
  bool consume() {
    if (state <= 0) return false;
    state--;
    return true;
  }
}

final feeWaiverCreditsProvider = NotifierProvider<FeeWaiverCredits, int>(FeeWaiverCredits.new);

class MerchantWalletPage extends ConsumerStatefulWidget {
  const MerchantWalletPage({super.key});

  @override
  ConsumerState<MerchantWalletPage> createState() => _MerchantWalletPageState();
}

class _MerchantWalletPageState extends ConsumerState<MerchantWalletPage> {
  int _amount = 10000;
  final _coupon = TextEditingController();
  String? _couponErr;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final env = ref.read(environmentProvider);
    final id = ref.read(myMerchantIdProvider);
    final c = env.coupons.byCode(_coupon.text.trim());
    final now = DateTime.now();
    if (c == null) {
      setState(() => _couponErr = 'Cupom não encontrado');
      return;
    }
    if (!c.isValidFor(id, now)) {
      setState(() => _couponErr = 'Cupom vencido, esgotado ou não vale para o seu comércio');
      return;
    }
    await env.coupons.save(c.copyWith(used: c.used + 1));
    if (c.kind == CouponKind.feeWaiver) ref.read(feeWaiverCreditsProvider.notifier).add(c.value);
    env.events.append(DomainEvent(type: 'coupon.applied', at: now, actorId: id, data: {'code': c.code}));
    setState(() => _couponErr = null);
    _coupon.clear();
    if (mounted) CorreToast.show(context, '${c.code} ativado: ${c.value} entregas sem taxa', tone: CorreTone.success);
  }

  Future<void> _topUp() async {
    final ok = await showCorreSheet<bool>(
      context,
      title: 'Pagar ${formatCents(_amount)} via Pix',
      child: Column(children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(border: Border.all(color: context.palette.line, width: 2), borderRadius: CorreRadius.mdAll),
          child: GridView.count(
            crossAxisCount: 9,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              for (var i = 0; i < 81; i++)
                Container(margin: const EdgeInsets.all(1), color: (i * 7 + i ~/ 9) % 3 == 0 ? context.palette.ink : Colors.transparent),
            ],
          ),
        ),
        const SizedBox(height: CorreSpace.sm),
        Text('QR Code de demonstração. Na versão real o Pix é gerado pelo Asaas e o saldo entra na hora.', style: context.text.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: CorreSpace.md),
        CorreButton(label: 'Simular pagamento recebido', onPressed: () => Navigator.of(context).pop(true)),
      ]),
    );
    if (ok != true) return;
    try {
      await ref.read(serviceProvider).topUp(ref.read(myMerchantIdProvider), _amount);
      if (mounted) CorreToast.show(context, 'Saldo recarregado', tone: CorreTone.success);
    } on BusinessError catch (e) {
      if (mounted) CorreToast.show(context, e.message, tone: CorreTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(myMerchantProvider);
    final entries = ref.watch(walletProvider(ref.watch(myMerchantIdProvider))).value ?? const [];
    final credits = ref.watch(feeWaiverCreditsProvider);
    if (m == null) return const SizedBox.shrink();

    return CorrePage(maxWidth: 1000, children: [
      Text('Carteira e plano', style: context.text.headlineSmall),
      const SizedBox(height: CorreSpace.md),
      CorreResponsiveGrid(desktopColumns: 2, tabletColumns: 2, children: [
        CorreCard(
          tone: CorreTone.brand,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Saldo pré-pago', style: context.text.bodyMedium),
            Text(formatCents(m.balance), style: context.text.displaySmall?.copyWith(color: context.palette.brand)),
            if (credits > 0) CorreBadge(label: '$credits entregas sem taxa', tone: CorreTone.success),
            const SizedBox(height: CorreSpace.md),
            CorreSegmented<int>(options: const {5000: 'R\$ 50', 10000: 'R\$ 100', 20000: 'R\$ 200', 50000: 'R\$ 500'}, value: _amount, onChanged: (v) => setState(() => _amount = v)),
            const SizedBox(height: CorreSpace.md),
            CorreButton(label: 'Recarregar via Pix', icon: Icons.pix, onPressed: _topUp),
          ]),
        ),
        CorreCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cupom', style: context.text.titleMedium),
            const SizedBox(height: CorreSpace.sm),
            CorreTextField(label: 'Código do cupom', controller: _coupon, hint: 'Ex.: BEMVINDO10', errorText: _couponErr),
            const SizedBox(height: CorreSpace.sm),
            CorreButton(label: 'Aplicar', variant: CorreButtonVariant.secondary, onPressed: _applyCoupon),
            const SizedBox(height: CorreSpace.xs),
            Text('Cupons de demonstração: BEMVINDO10, VEMDA99, INDICA20.', style: context.text.bodySmall),
          ]),
        ),
      ]),
      const CorreSectionHeader(title: 'Plano'),
      CorreResponsiveGrid(desktopColumns: 2, tabletColumns: 2, children: [
        CorreCard(
          highlighted: m.plan == MerchantPlan.payPerUse,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('Avulso', style: context.text.titleMedium)), const CorreBadge(label: 'Atual', tone: CorreTone.brand)]),
            Text('Sem mensalidade · R\$ 1,50 por entrega · 0% sobre o pedido', style: context.text.bodyMedium),
          ]),
        ),
        CorreCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('Parceiro', style: context.text.titleMedium)), const CorreBadge(label: 'Em breve')]),
            Text('Mensalidade fixa com taxa menor por entrega. Vale a partir de ~100 entregas por mês.', style: context.text.bodyMedium),
          ]),
        ),
      ]),
      const CorreSectionHeader(title: 'Extrato'),
      if (entries.isEmpty)
        const CorreCard(child: CorreEmptyState(icon: Icons.receipt_long_outlined, title: 'Sem lançamentos'))
      else
        CorreDataTable(
          columns: const ['Data', 'Descrição', 'Valor'],
          rows: [
            for (final e in entries.take(100))
              [
                Text('${ddmm(e.at)} ${hhmm(e.at)}'),
                Text(e.description),
                Text(formatCents(e.amount), style: TextStyle(color: e.amount >= 0 ? context.palette.success : null, fontWeight: FontWeight.w600)),
              ],
          ],
        ),
    ]);
  }
}
