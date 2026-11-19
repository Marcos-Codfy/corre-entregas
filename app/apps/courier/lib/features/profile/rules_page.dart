import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/courier_controller.dart';

/// Regras públicas: frete, nota, adicionais e o que acontece em cada caso.
class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    final p = ref.read(serviceProvider).pricing;
    final r = p.rules;
    final rating = me?.rating;
    return Scaffold(
      appBar: AppBar(title: const Text('Nota e regras')),
      body: ListView(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          CorreCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sua nota', style: context.text.bodyMedium),
                Row(
                  children: [
                    Text(
                      rating == null ? 'Novo' : rating.toStringAsFixed(1).replaceAll('.', ','),
                      style: context.text.displaySmall,
                    ),
                    const SizedBox(width: CorreSpace.sm),
                    CorreRating(value: (rating ?? 5).round(), size: 22),
                  ],
                ),
                Text(
                  'Média das últimas 30 avaliações. Aparece depois de 5. Recusar corrida nunca bloqueia.',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const CorreSectionHeader(title: 'Tabela de frete (100% para você)'),
          CorreCard(
            child: Column(
              children: [
                CorreKeyValue(label: 'Até ${r.baseKm.toStringAsFixed(0)} km', value: formatCents(r.baseFreight)),
                CorreKeyValue(label: 'Cada km a mais', value: formatCents(r.perExtraKm)),
                for (final d in [3.0, 6.0, 8.0, 10.0])
                  CorreKeyValue(label: 'Exemplo: ${km(d)}', value: formatCents(p.freightFor(d))),
              ],
            ),
          ),
          const CorreSectionHeader(title: 'Adicionais'),
          CorreCard(
            child: Column(
              children: [
                CorreKeyValue(label: 'Chuva ou depois das 23h', value: '+${formatCents(r.rainOrLateNight)}'),
                CorreKeyValue(label: 'Segunda parada na mesma rota', value: '+${formatCents(r.extraStop)}'),
                CorreKeyValue(
                  label: 'Espera no comércio (a cada 10 min após 10 min)',
                  value: '+${formatCents(r.waitFeePer10Min)}',
                ),
                CorreKeyValue(label: 'Retorno com cliente ausente', value: '+${r.returnPercent}% do frete'),
                CorreKeyValue(label: 'Ninguém aceitou em 5 min', value: '+${formatCents(r.escalationStep)}'),
                CorreKeyValue(label: 'Comércio cancelou depois de você rodar 1 km', value: formatCents(r.cancelFee)),
              ],
            ),
          ),
          const CorreSectionHeader(title: 'Como funciona'),
          const CorreCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rule(
                  icon: Icons.favorite_outline,
                  text: 'Comércios podem marcar até 3 motoboys preferidos. Eles recebem a oferta primeiro.',
                ),
                _Rule(
                  icon: Icons.timer_outlined,
                  text: 'Cada oferta fica 20 s com você. Depois vai para o próximo, por proximidade (5, 7 e 10 km).',
                ),
                _Rule(
                  icon: Icons.star_outline,
                  text: 'Nota abaixo de 4,0: você sai da fila automática e o suporte conversa com você antes de qualquer bloqueio.',
                ),
                _Rule(
                  icon: Icons.pin_outlined,
                  text: 'A entrega só é confirmada com o código de 4 dígitos do cliente.',
                ),
                _Rule(icon: Icons.money_off, text: 'Você não cobra nada na porta. O cliente já pagou o comércio.'),
                _Rule(
                  icon: Icons.gavel_outlined,
                  text: 'Antes de qualquer suspensão você é avisado e pode se explicar com o suporte.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CorreSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.palette.brand),
        const SizedBox(width: CorreSpace.md),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}
