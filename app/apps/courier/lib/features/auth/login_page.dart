import 'package:corre_design_system/corre_design_system.dart';
import 'package:corre_shared/corre_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Entrada. Na Onda 1 o login é simulado: qualquer e-mail e senha entram no perfil de demonstração.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController(text: 'diego@exemplo.com');
  final _password = TextEditingController(text: '12345678');
  String? _emailError, _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final email = _email.text.trim();
    setState(() {
      _emailError = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ? null : 'Informe um e-mail válido';
      _passwordError = _password.text.length >= 6 ? null : 'A senha tem pelo menos 6 caracteres';
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    ref.read(sessionProvider.notifier).signIn(DemoRole.courier);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CorreSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: CorreLogo(size: 48)),
                const SizedBox(height: CorreSpace.sm),
                Text(
                  'Entregas dos comércios de Palmas.\nVocê escolhe quando rodar.',
                  style: context.text.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CorreSpace.xxl),
                CorreTextField(
                  label: 'E-mail',
                  controller: _email,
                  errorText: _emailError,
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: CorreSpace.md),
                CorrePasswordField(controller: _password, errorText: _passwordError),
                const SizedBox(height: CorreSpace.lg),
                CorreButton(label: 'Entrar', loading: _loading, onPressed: _enter),
                const SizedBox(height: CorreSpace.sm),
                CorreButton(
                  label: 'Entrar com Google',
                  icon: Icons.account_circle_outlined,
                  variant: CorreButtonVariant.ghost,
                  onPressed: _loading ? null : () => ref.read(sessionProvider.notifier).signIn(DemoRole.courier),
                ),
                const SizedBox(height: CorreSpace.xl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: CorreSpace.sm),
                        child: Text(
                          'Ainda não roda com a gente?',
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: CorreSpace.md),
                CorreButton(
                  label: 'Quero me cadastrar',
                  variant: CorreButtonVariant.secondary,
                  onPressed: () => context.push(Routes.signup),
                ),
                const SizedBox(height: CorreSpace.xl),
                const CorreBanner(
                  icon: Icons.science_outlined,
                  message: 'Versão de demonstração: os dados são fictícios e ficam só neste aparelho.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
