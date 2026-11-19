import 'package:corre_core/corre_core.dart';
import 'package:corre_design_system/corre_design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Regras de cadastro do motoboy (decisão do MVP; rever a lei antes do lançamento).
abstract final class SignupRules {
  static const minAge = 18;

  static String? validateBirthYear(String v, {int? currentYear}) {
    final y = int.tryParse(v);
    final now = currentYear ?? DateTime.now().year;
    if (y == null || y < 1940 || y > now) return 'Ano inválido';
    if (now - y < minAge) return 'É preciso ter $minAge anos ou mais';
    return null;
  }

  static String? validateCpf(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return 'CPF inválido';
    int digit(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += int.parse(d[i]) * (len + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    return digit(9) == int.parse(d[9]) && digit(10) == int.parse(d[10]) ? null : 'CPF inválido';
  }
}

/// Cadastro em etapas: dados, moto, documentos e confirmação.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _step = 0;
  final _name = TextEditingController();
  final _cpf = TextEditingController();
  final _birth = TextEditingController();
  final _phone = TextEditingController();
  String _bike = 'Honda CG 160';
  final _sent = <DocumentKind>{};
  bool _ear = false, _terms = false;
  String? _nameErr, _cpfErr, _birthErr, _phoneErr;

  static const bikes = [
    'Honda CG 160',
    'Honda Fan 160',
    'Honda Pop 110i',
    'Honda Biz 125',
    'Yamaha Factor 150',
    'Yamaha Fazer 250',
    'Outra',
  ];

  @override
  void dispose() {
    for (final c in [_name, _cpf, _birth, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    setState(() {
      if (_step == 0) {
        _nameErr = _name.text.trim().split(' ').length >= 2 ? null : 'Nome e sobrenome';
        _cpfErr = SignupRules.validateCpf(_cpf.text);
        _birthErr = SignupRules.validateBirthYear(_birth.text);
        _phoneErr = _phone.text.replaceAll(RegExp(r'\D'), '').length == 11 ? null : 'Celular com DDD';
      }
    });
    return switch (_step) {
      0 => [_nameErr, _cpfErr, _birthErr, _phoneErr].every((e) => e == null),
      1 => _ear,
      2 => _sent.length == DocumentKind.values.length,
      _ => _terms,
    };
  }

  void _next() {
    if (!_validateStep()) {
      if (_step == 1) CorreToast.show(context, 'Confirme que sua CNH tem a observação EAR', tone: CorreTone.warning);
      if (_step == 2) CorreToast.show(context, 'Envie todos os documentos', tone: CorreTone.warning);
      if (_step == 3) CorreToast.show(context, 'Aceite os termos para continuar', tone: CorreTone.warning);
      return;
    }
    if (_step == 3) {
      context.go(Routes.approval);
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Seus dados', 'Sua moto e CNH', 'Documentos', 'Confirmação'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro · ${_step + 1} de 4'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
        ),
      ),
      body: CorreReadableList(
        padding: const EdgeInsets.all(CorreSpace.lg),
        children: [
          CorreProgressBar(value: (_step + 1) / 4),
          const SizedBox(height: CorreSpace.lg),
          Text(titles[_step], style: context.text.headlineSmall),
          const SizedBox(height: CorreSpace.lg),
          ...switch (_step) {
            0 => [
              CorreTextField(label: 'Nome completo', controller: _name, errorText: _nameErr),
              const SizedBox(height: CorreSpace.md),
              CorreTextField(
                label: 'CPF',
                controller: _cpf,
                errorText: _cpfErr,
                keyboardType: TextInputType.number,
                hint: 'Só números',
              ),
              const SizedBox(height: CorreSpace.md),
              CorreTextField(
                label: 'Ano de nascimento',
                controller: _birth,
                errorText: _birthErr,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: CorreSpace.md),
              CorreTextField(
                label: 'Celular (WhatsApp)',
                controller: _phone,
                errorText: _phoneErr,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
              ),
            ],
            1 => [
              CorreDropdown<String>(
                label: 'Modelo da moto',
                items: {for (final b in bikes) b: b},
                value: _bike,
                onChanged: (v) => setState(() => _bike = v ?? _bike),
              ),
              const SizedBox(height: CorreSpace.xs),
              Text(
                'Guardamos só o modelo. Placa e chassi ficam no documento, que só o suporte vê.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: CorreSpace.lg),
              const CorreBanner(
                icon: Icons.badge_outlined,
                message: 'Aceitamos CNH categoria A definitiva com a observação EAR (exerce atividade remunerada). Permissão para dirigir não é aceita.',
              ),
              CorreCheckbox(
                label: 'Minha CNH é categoria A, definitiva e tem EAR',
                value: _ear,
                onChanged: (v) => setState(() => _ear = v ?? false),
              ),
            ],
            2 => [
              for (final k in DocumentKind.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: CorreSpace.sm),
                  child: CorreCard(
                    onTap: () => setState(() => _sent.contains(k) ? _sent.remove(k) : _sent.add(k)),
                    child: Row(
                      children: [
                        Icon(
                          _sent.contains(k) ? Icons.check_circle : Icons.upload_file,
                          color: _sent.contains(k) ? context.palette.success : context.palette.ink2,
                        ),
                        const SizedBox(width: CorreSpace.md),
                        Expanded(child: Text(k.label, style: context.text.titleSmall)),
                        CorreBadge(
                          label: _sent.contains(k) ? 'Enviado' : 'Enviar',
                          tone: _sent.contains(k) ? CorreTone.success : CorreTone.neutral,
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                'Na demonstração, tocar no documento marca como enviado. Na versão real abre a câmera.',
                style: context.text.bodySmall,
              ),
            ],
            _ => [
              CorreCard(
                child: Column(
                  children: [
                    CorreKeyValue(label: 'Nome', value: _name.text),
                    CorreKeyValue(label: 'Celular', value: _phone.text),
                    CorreKeyValue(label: 'Moto', value: _bike),
                    CorreKeyValue(label: 'Documentos', value: '${_sent.length} de ${DocumentKind.values.length}'),
                  ],
                ),
              ),
              const SizedBox(height: CorreSpace.md),
              Text(
                'Como funciona: o suporte confere seus documentos em até 24 h. Você recebe o aviso por WhatsApp. '
                'Você é autônomo: escolhe quando ficar online, pode recusar corridas sem punição e recebe 100% do frete por Pix.',
                style: context.text.bodyMedium,
              ),
              CorreCheckbox(
                label: 'Li e aceito os termos de uso e a política de privacidade',
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
              ),
            ],
          },
          const SizedBox(height: CorreSpace.xl),
          CorreButton(label: _step == 3 ? 'Enviar cadastro' : 'Continuar', onPressed: _next),
        ],
      ),
    );
  }
}
