import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrada do painel. Na demonstração, basta escolher o perfil.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  DemoRole _role = DemoRole.merchantOwner;

  static const _profiles = {
    DemoRole.merchantOwner: ('Burger da 106', 'Pede entregas, acompanha, recarrega saldo e gerencia a equipe.', Icons.storefront),
    DemoRole.merchantStaff: ('Atendente do Burger da 106', 'Pede e acompanha entregas, sem acesso ao financeiro.', Icons.badge_outlined),
    DemoRole.support: ('Suporte', 'Acompanha ao vivo, despacha na mão, resolve ocorrências e aprova cadastros.', Icons.support_agent),
    DemoRole.admin: ('Administrador', 'Tudo do suporte + indicadores, preços, cupons e repasses.', Icons.admin_panel_settings_outlined),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CorreSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: CorreLogo(size: 44, subtitle: 'painel')),
                const SizedBox(height: CorreSpace.sm),
                Text('Motoboy na porta em minutos, sem % sobre o pedido.', style: context.text.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: CorreSpace.xl),
                const CorreTextField(label: 'E-mail', initialValue: 'contato@burgerda106.com.br', prefixIcon: Icons.mail_outline),
                const SizedBox(height: CorreSpace.md),
                const CorrePasswordField(initialValue: '12345678'),
                const SizedBox(height: CorreSpace.xl),
                Text('Entrar como (demonstração)', style: context.text.titleMedium),
                const SizedBox(height: CorreSpace.sm),
                for (final e in _profiles.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: CorreSpace.sm),
                    child: CorreCard(
                      highlighted: _role == e.key,
                      onTap: () => setState(() => _role = e.key),
                      child: Row(children: [
                        Icon(e.value.$3, color: _role == e.key ? context.palette.brand : context.palette.ink2),
                        const SizedBox(width: CorreSpace.md),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.value.$1, style: context.text.titleSmall),
                            Text(e.value.$2, style: context.text.bodySmall),
                          ]),
                        ),
                        Icon(_role == e.key ? Icons.radio_button_checked : Icons.radio_button_off, color: _role == e.key ? context.palette.brand : context.palette.ink3),
                      ]),
                    ),
                  ),
                const SizedBox(height: CorreSpace.md),
                CorreButton(label: 'Entrar', size: CorreButtonSize.large, onPressed: () => ref.read(sessionProvider.notifier).signIn(_role)),
                const SizedBox(height: CorreSpace.lg),
                const CorreBanner(
                  icon: Icons.science_outlined,
                  message: 'Versão de demonstração: dados fictícios, guardados só neste navegador. Motoboys e clientes são simulados.',
                ),
              ]),
            ),
          ),
        ),
      );
}
