import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'run_controller.dart';

/// Prova de entrega: só com o código de 4 dígitos do cliente (sem foto).
class ProofPage extends ConsumerStatefulWidget {
  const ProofPage({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  ConsumerState<ProofPage> createState() => _ProofPageState();
}

class _ProofPageState extends ConsumerState<ProofPage> {
  String? _error;
  int _attempts = 0;
  bool _busy = false;

  Future<void> _submit(Delivery d, String code, {bool viaMerchant = false}) async {
    setState(() => _busy = true);
    try {
      final ok = await ref.read(runControllerProvider).confirm(d, code, viaMerchant: viaMerchant);
      if (!mounted) return;
      if (ok) {
        CorreToast.show(context, 'Entrega confirmada · +${formatCents(d.courierAmount)}', tone: CorreTone.success);
        context.pop();
      } else {
        setState(() {
          _attempts++;
          _error = 'Código não confere. Peça ao cliente para conferir a mensagem do comércio.';
        });
      }
    } on BusinessError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(deliveryProvider(widget.deliveryId)).value;
    if (d == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final merchant = ref.watch(merchantProvider(d.merchantId)).value;
    final demoHint =
        'Demonstração: o código desta entrega é ${d.deliveryCode} (ou ${d.customer.fallbackCode}, os 4 últimos dígitos do telefone).';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar entrega')),
      body: CorreReadableList(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          Text('Peça o código ao cliente', style: context.text.headlineSmall),
          const SizedBox(height: CorreSpace.xs),
          Text(
            '${d.customer.firstName} recebeu o código de 4 dígitos na mensagem do ${merchant?.name ?? 'comércio'}.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: CorreSpace.xl),
          CorreCodeInput(key: ValueKey(_attempts), errorText: _error, onCompleted: (c) => _submit(d, c)),
          const SizedBox(height: CorreSpace.lg),
          if (_busy) const Center(child: CircularProgressIndicator()),
          CorreBanner(message: demoHint, icon: Icons.science_outlined),
          const SizedBox(height: CorreSpace.xl),
          CorreCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente sem o código?', style: context.text.titleMedium),
                const SizedBox(height: CorreSpace.xs),
                Text(
                  'Ligue para o comércio. Ele confirma a entrega pelo painel e o caso fica registrado para o suporte.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: CorreSpace.md),
                CorreButton(
                  label: 'Ligar para o comércio',
                  icon: Icons.phone,
                  variant: CorreButtonVariant.secondary,
                  onPressed: () => ExternalLinks.open(ExternalLinks.phone(merchant?.phone ?? '')),
                ),
                const SizedBox(height: CorreSpace.sm),
                CorreButton(
                  label: 'Comércio confirmou (demonstração)',
                  variant: CorreButtonVariant.ghost,
                  onPressed: _busy ? null : () => _submit(d, '', viaMerchant: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
