import 'package:meta/meta.dart';

/// Valores em centavos para evitar erro de arredondamento.
typedef Cents = int;

/// Regras de preço da plataforma. Valores padrão = decisões do MVP.
@immutable
class PricingRules {
  const PricingRules({
    this.baseFreight = 800,
    this.baseKm = 5,
    this.perExtraKm = 150,
    this.kmRoundingStep = .5,
    this.platformFee = 150,
    this.extraStop = 200,
    this.rainOrLateNight = 300,
    this.returnPercent = 50,
    this.waitFeePer10Min = 100,
    this.freeWaitMinutes = 10,
    this.cancelFee = 300,
    this.cancelFeeMinKm = 1,
    this.escalationStep = 100,
    this.escalationMonthlyBudget = 5000,
  });

  /// Frete até [baseKm] (R$ 8,00).
  final Cents baseFreight;
  final double baseKm;

  /// Valor por km acima de [baseKm] (R$ 1,50).
  final Cents perExtraKm;

  /// Distância extra arredondada para cima neste passo (0,5 km).
  final double kmRoundingStep;

  /// Taxa da plataforma por entrega, paga pelo comércio (modelo A).
  final Cents platformFee;

  /// Segunda parada na mesma rota (2 clientes do mesmo comércio).
  final Cents extraStop;

  /// Adicional de chuva ou após 23h.
  final Cents rainOrLateNight;

  /// Retorno ao comércio quando o cliente está ausente (% do frete).
  final int returnPercent;

  /// Espera no comércio: a cada 10 min além de [freeWaitMinutes].
  final Cents waitFeePer10Min;
  final int freeWaitMinutes;

  /// Cancelamento após o aceite: só se o motoboy já rodou [cancelFeeMinKm].
  final Cents cancelFee;
  final double cancelFeeMinKm;

  /// Aumento quando ninguém aceita em 5 min, pago pela plataforma até o teto mensal.
  final Cents escalationStep;
  final Cents escalationMonthlyBudget;

  PricingRules copyWith({
    Cents? baseFreight,
    double? baseKm,
    Cents? perExtraKm,
    Cents? platformFee,
    Cents? extraStop,
    Cents? rainOrLateNight,
    Cents? cancelFee,
    Cents? escalationMonthlyBudget,
  }) =>
      PricingRules(
        baseFreight: baseFreight ?? this.baseFreight,
        baseKm: baseKm ?? this.baseKm,
        perExtraKm: perExtraKm ?? this.perExtraKm,
        kmRoundingStep: kmRoundingStep,
        platformFee: platformFee ?? this.platformFee,
        extraStop: extraStop ?? this.extraStop,
        rainOrLateNight: rainOrLateNight ?? this.rainOrLateNight,
        returnPercent: returnPercent,
        waitFeePer10Min: waitFeePer10Min,
        freeWaitMinutes: freeWaitMinutes,
        cancelFee: cancelFee ?? this.cancelFee,
        cancelFeeMinKm: cancelFeeMinKm,
        escalationStep: escalationStep,
        escalationMonthlyBudget: escalationMonthlyBudget ?? this.escalationMonthlyBudget,
      );
}

/// Resultado de uma cotação.
@immutable
class Quote {
  const Quote({required this.distanceKm, required this.freight, required this.platformFee, required this.extras});
  final double distanceKm;

  /// Valor que vai 100% para o motoboy (frete + adicionais).
  final Cents freight;
  final Cents platformFee;
  final Cents extras;

  Cents get courierAmount => freight + extras;
  Cents get merchantTotal => freight + extras + platformFee;
}

/// Calcula fretes, adicionais e taxas a partir das [PricingRules].
class PricingService {
  const PricingService([this.rules = const PricingRules()]);
  final PricingRules rules;

  /// Distância extra cobrada, arredondada para cima em passos de 0,5 km.
  double chargeableExtraKm(double distanceKm) {
    if (distanceKm.isNaN || distanceKm <= rules.baseKm) return 0;
    final extra = distanceKm - rules.baseKm;
    final steps = (extra / rules.kmRoundingStep - 1e-9).ceil();
    return steps * rules.kmRoundingStep;
  }

  Cents freightFor(double distanceKm) {
    if (distanceKm < 0) throw ArgumentError.value(distanceKm, 'distanceKm', 'não pode ser negativa');
    return rules.baseFreight + (chargeableExtraKm(distanceKm) * rules.perExtraKm).round();
  }

  Quote quote(double distanceKm, {int extraStops = 0, bool rainOrLateNight = false}) {
    if (extraStops < 0) throw ArgumentError.value(extraStops, 'extraStops');
    final extras = extraStops * rules.extraStop + (rainOrLateNight ? rules.rainOrLateNight : 0);
    return Quote(distanceKm: distanceKm, freight: freightFor(distanceKm), platformFee: rules.platformFee, extras: extras);
  }

  /// Taxa de espera no comércio após [waitedMinutes].
  Cents waitFee(int waitedMinutes) {
    if (waitedMinutes <= rules.freeWaitMinutes) return 0;
    return ((waitedMinutes - rules.freeWaitMinutes) / 10).ceil() * rules.waitFeePer10Min;
  }

  /// Valor do retorno ao comércio (cliente ausente).
  Cents returnFee(Cents freight) => (freight * rules.returnPercent / 100).round();

  /// Taxa ao cancelar: zero antes do aceite ou se o motoboy rodou menos de 1 km.
  Cents cancellationFee({required bool accepted, required double courierTraveledKm}) {
    if (!accepted) return 0;
    return courierTraveledKm >= rules.cancelFeeMinKm ? rules.cancelFee : 0;
  }

  /// Aumento de escalonamento que a plataforma ainda pode pagar neste mês.
  Cents escalationAvailable(Cents spentThisMonth) {
    final left = rules.escalationMonthlyBudget - spentThisMonth;
    if (left <= 0) return 0;
    return left < rules.escalationStep ? left : rules.escalationStep;
  }
}

/// Formata centavos em reais: 950 → "R$ 9,50".
String formatCents(Cents cents) {
  final neg = cents < 0;
  final abs = cents.abs();
  final reais = (abs ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final c = (abs % 100).toString().padLeft(2, '0');
  final sign = neg ? '−' : '';
  return '${sign}R\$ $reais,$c';
}
