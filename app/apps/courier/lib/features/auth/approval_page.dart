import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Cadastro enviado: aguardando a conferência do suporte.
class ApprovalPage extends ConsumerWidget {
  const ApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CorreSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CorreEmptyState(
              icon: Icons.hourglass_top_rounded,
              tone: CorreTone.warning,
              title: 'Cadastro em análise',
              message: 'O suporte confere seus documentos em até 24 h e avisa por WhatsApp. Enquanto isso, veja as regras e a tabela de frete no seu perfil.',
            ),
            const CorreCard(
              child: CorreStepTimeline(
                steps: [
                  CorreStep('Cadastro enviado', CorreStepState.done),
                  CorreStep('Conferência dos documentos', CorreStepState.current),
                  CorreStep('Conversa rápida com o suporte', CorreStepState.pending),
                  CorreStep('Liberado para rodar', CorreStepState.pending),
                ],
              ),
            ),
            const SizedBox(height: CorreSpace.xl),
            CorreButton(
              label: 'Simular aprovação e entrar',
              icon: Icons.science_outlined,
              onPressed: () {
                ref.read(sessionProvider.notifier).signIn(DemoRole.courier);
                context.go(Routes.home);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
