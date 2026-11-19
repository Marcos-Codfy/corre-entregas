import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = {
    'Quando recebo o dinheiro?':
        'O frete fica na carteira assim que a entrega é confirmada. O saque por Pix é grátis e cai no mesmo dia.',
    'Posso recusar corridas?': 'Pode. Recusar ou deixar o tempo acabar não gera punição nem bloqueio.',
    'O cliente não está em casa. E agora?': 'Toque em "Cliente não está", ligue para ele e para o comércio e espere 10 min. Depois você pode devolver o pedido e recebe +50% do frete.',
    'Sofri um acidente.': 'Primeiro sua segurança. Depois toque em "Relatar problema" na corrida. O suporte liga para você e o repasse dessa entrega fica guardado até resolver.',
    'Como sobe minha nota?': 'Chegar no horário, tratar bem comércio e cliente e confirmar a entrega pelo código.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajuda e suporte')),
    body: CorreReadableList(
      padding: const EdgeInsets.all(CorreSpace.lg),
      children: [
        CorreCard(
          tone: CorreTone.brand,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suporte local em Palmas', style: context.text.titleMedium),
              const SizedBox(height: CorreSpace.xs),
              Text('Quem atende também é motoboy. Todos os dias, das 10h às 23h.', style: context.text.bodyMedium),
              const SizedBox(height: CorreSpace.md),
              CorreButton(
                label: 'Chamar no WhatsApp',
                icon: Icons.chat_outlined,
                onPressed: () =>
                    ExternalLinks.open(ExternalLinks.whatsapp('63900000000', 'Olá, preciso de ajuda com uma corrida.')),
              ),
            ],
          ),
        ),
        const CorreSectionHeader(title: 'Perguntas frequentes'),
        CorreCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final e in _faq.entries)
                ExpansionTile(
                  title: Text(e.key, style: context.text.titleSmall),
                  childrenPadding: const EdgeInsets.fromLTRB(CorreSpace.lg, 0, CorreSpace.lg, CorreSpace.lg),
                  children: [Text(e.value, style: context.text.bodyMedium)],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
