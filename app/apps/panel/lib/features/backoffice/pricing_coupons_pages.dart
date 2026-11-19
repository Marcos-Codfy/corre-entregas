import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Converte "R$ 8,00" ou "8,00" em centavos.
int? parseCents(String text) {
  final d = text.replaceAll(RegExp(r'\D'), '');
  return d.isEmpty ? null : int.parse(d);
}

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({super.key});

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  late final PricingRules _r = ref.read(serviceProvider).pricing.rules;
  late final _base = TextEditingController(text: formatCents(_r.baseFreight));
  late final _perKm = TextEditingController(text: formatCents(_r.perExtraKm));
  late final _fee = TextEditingController(text: formatCents(_r.platformFee));
  late final _rain = TextEditingController(text: formatCents(_r.rainOrLateNight));
  double _simKm = 6;

  @override
  void dispose() {
    for (final c in [_base, _perKm, _fee, _rain]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final service = ref.read(serviceProvider);
    try {
      service.updatePricing(
        service.pricing.rules.copyWith(
          baseFreight: parseCents(_base.text),
          perExtraKm: parseCents(_perKm.text),
          platformFee: parseCents(_fee.text),
          rainOrLateNight: parseCents(_rain.text),
        ),
        adminId: Seed.adminUserId,
      );
      setState(() {});
      CorreToast.show(context, 'Preços atualizados. Valem para as próximas entregas.', tone: CorreTone.success);
    } on BusinessError catch (e) {
      CorreToast.show(context, e.message, tone: CorreTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.read(serviceProvider).pricing;
    final q = p.quote(_simKm);
    return CorrePage(maxWidth: 900, children: [
      Text('Preços', style: context.text.headlineSmall),
      Text('Frete vai 100% para o motoboy; a plataforma fica só com a taxa por entrega.', style: context.text.bodyMedium),
      const SizedBox(height: CorreSpace.md),
      CorreCard(
        child: Column(children: [
          CorreResponsiveGrid(desktopColumns: 2, tabletColumns: 2, children: [
            CorreTextField(label: 'Frete até ${p.rules.baseKm.toStringAsFixed(0)} km', controller: _base, inputFormatters: [CurrencyInputFormatter()]),
            CorreTextField(label: 'Por km adicional', controller: _perKm, inputFormatters: [CurrencyInputFormatter()]),
            CorreTextField(label: 'Taxa da plataforma', controller: _fee, inputFormatters: [CurrencyInputFormatter()]),
            CorreTextField(label: 'Chuva ou após 23h', controller: _rain, inputFormatters: [CurrencyInputFormatter()]),
          ]),
          const SizedBox(height: CorreSpace.md),
          CorreButton(label: 'Salvar preços', onPressed: _save),
        ]),
      ),
      const CorreSectionHeader(title: 'Simulador'),
      CorreCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Distância: ${km(_simKm)}', style: context.text.titleSmall),
          Slider(value: _simKm, min: .5, max: 15, divisions: 29, label: km(_simKm), onChanged: (v) => setState(() => _simKm = v)),
          CorreKeyValue(label: 'Motoboy recebe', value: formatCents(q.courierAmount)),
          CorreKeyValue(label: 'Plataforma', value: formatCents(q.platformFee)),
          CorreKeyValue(label: 'Comércio paga', value: formatCents(q.merchantTotal), emphasize: true),
          CorreKeyValue(label: 'iFood Entrega num pedido de R\$ 50 (26,2%)', value: formatCents(1310)),
        ]),
      ),
      const CorreSectionHeader(title: 'Regras fixas'),
      CorreCard(
        child: Column(children: [
          CorreKeyValue(label: 'Cancelamento após o motoboy rodar ${p.rules.cancelFeeMinKm.toStringAsFixed(0)} km', value: formatCents(p.rules.cancelFee)),
          CorreKeyValue(label: 'Retorno com cliente ausente', value: '+${p.rules.returnPercent}% do frete'),
          CorreKeyValue(label: 'Escalonamento (5 min sem aceite)', value: '+${formatCents(p.rules.escalationStep)} · teto ${formatCents(p.rules.escalationMonthlyBudget)}/mês'),
          CorreKeyValue(label: 'Espera no comércio', value: '+${formatCents(p.rules.waitFeePer10Min)} a cada 10 min após ${p.rules.freeWaitMinutes} min'),
        ]),
      ),
    ]);
  }
}

class CouponsAdminPage extends ConsumerWidget {
  const CouponsAdminPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final value = TextEditingController(text: '10');
    final uses = TextEditingController(text: '50');
    var days = 30;
    var kind = CouponKind.feeWaiver;
    final ok = await showCorreSheet<bool>(
      context,
      title: 'Novo cupom',
      child: StatefulBuilder(
        builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CorreTextField(label: 'Código', controller: code, hint: 'Ex.: NATAL15'),
          const SizedBox(height: CorreSpace.sm),
          CorreSegmented<CouponKind>(options: {for (final k in CouponKind.values) k: k.label}, value: kind, onChanged: (k) => setState(() => kind = k)),
          const SizedBox(height: CorreSpace.sm),
          CorreTextField(label: kind == CouponKind.feeWaiver ? 'Quantidade de entregas sem taxa' : 'Desconto na taxa (centavos)', controller: value, keyboardType: TextInputType.number),
          const SizedBox(height: CorreSpace.sm),
          CorreTextField(label: 'Limite de usos', controller: uses, keyboardType: TextInputType.number),
          const SizedBox(height: CorreSpace.sm),
          CorreSegmented<int>(options: const {7: '7 dias', 30: '30 dias', 90: '90 dias'}, value: days, onChanged: (d) => setState(() => days = d)),
          const SizedBox(height: CorreSpace.md),
          CorreButton(label: 'Criar cupom', onPressed: () => Navigator.of(context).pop(true)),
        ]),
      ),
    );
    final c = code.text.trim().toUpperCase();
    final v = int.tryParse(value.text), u = int.tryParse(uses.text);
    for (final ctrl in [code, value, uses]) {
      ctrl.dispose();
    }
    if (ok != true) return;
    if (!context.mounted) return;
    final env = ref.read(environmentProvider);
    if (!RegExp(r'^[A-Z0-9]{4,16}$').hasMatch(c) || v == null || v <= 0 || u == null || u <= 0) {
      CorreToast.show(context, 'Código de 4 a 16 letras/números e valores maiores que zero', tone: CorreTone.error);
      return;
    }
    if (env.coupons.byCode(c) != null) {
      CorreToast.show(context, 'Já existe um cupom $c', tone: CorreTone.error);
      return;
    }
    await env.coupons.save(Coupon(code: c, kind: kind, value: v, maxUses: u, validUntil: DateTime.now().add(Duration(days: days))));
    env.events.append(DomainEvent(type: 'coupon.created', at: DateTime.now(), actorId: Seed.adminUserId, data: {'code': c}));
    if (context.mounted) CorreToast.show(context, 'Cupom $c criado', tone: CorreTone.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(couponsProvider).value ?? const <Coupon>[];
    final now = DateTime.now();
    return CorrePage(maxWidth: 1000, children: [
      Row(children: [
        Expanded(child: Text('Cupons', style: context.text.headlineSmall)),
        CorreButton(label: 'Novo cupom', icon: Icons.add, expand: false, onPressed: () => _create(context, ref)),
      ]),
      const SizedBox(height: CorreSpace.md),
      CorreDataTable(
        columns: const ['Código', 'Tipo', 'Valor', 'Usos', 'Validade', 'Situação', ''],
        rows: [
          for (final c in coupons)
            [
              Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(c.kind.label),
              Text(c.kind == CouponKind.feeWaiver ? '${c.value} entregas' : formatCents(c.value)),
              Text('${c.used}/${c.maxUses}'),
              Text(ddmm(c.validUntil)),
              CorreBadge(
                label: c.isValidFor('', now) ? 'Ativo' : 'Inativo',
                tone: c.isValidFor('', now) ? CorreTone.success : CorreTone.neutral,
              ),
              Switch.adaptive(value: c.active, onChanged: (v) => ref.read(environmentProvider).coupons.save(c.copyWith(active: v))),
            ],
        ],
      ),
    ]);
  }
}
