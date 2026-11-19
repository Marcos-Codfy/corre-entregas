import 'package:meta/meta.dart';

import 'entities.dart';
import 'geo.dart';

/// Regras de despacho (ver docs/03-produto.md).
@immutable
class DispatchRules {
  const DispatchRules({
    this.offerTimeout = const Duration(seconds: 20),
    this.radiiKm = const [5, 7],
    this.broadcastRadiusKm = 10,
    this.escalateAfter = const Duration(minutes: 5),
    this.giveUpAfter = const Duration(minutes: 10),
    this.minRating = 4.0,
  });

  /// Tempo que cada motoboy tem para aceitar.
  final Duration offerTimeout;

  /// Raios da cascata, em ordem.
  final List<double> radiiKm;

  /// Depois da cascata, oferta para todos neste raio.
  final double broadcastRadiusKm;
  final Duration escalateAfter, giveUpAfter;

  /// Nota mínima para receber ofertas automáticas (abaixo disso, análise do suporte).
  final double minRating;
}

/// Uma rodada do despacho: quem recebe a oferta e por quê.
@immutable
class DispatchStep {
  const DispatchStep({required this.courierIds, required this.reason});
  final List<String> courierIds;

  /// preferred, radius:5, radius:7, broadcast
  final String reason;
  bool get isBroadcast => reason == 'broadcast';
}

/// Monta a fila de ofertas: preferidos → cascata por raio → broadcast.
class DispatchPlanner {
  const DispatchPlanner([this.rules = const DispatchRules()]);
  final DispatchRules rules;

  /// Pode receber oferta automática?
  bool isEligible(Courier c) {
    if (c.approval != ApprovalStatus.approved || !c.isFree) return false;
    if (c.documents.values.any((s) => s != ApprovalStatus.approved)) return false;
    final r = c.rating;
    return r == null || r >= rules.minRating; // sem nota ainda: novato pode receber
  }

  /// Plano completo, em ordem. Cada motoboy aparece no máximo uma vez fora do broadcast.
  List<DispatchStep> plan({required Merchant merchant, required List<Courier> couriers, Set<String> exclude = const {}}) {
    final pickup = merchant.address.point;
    final eligible = couriers.where((c) => isEligible(c) && !exclude.contains(c.id)).toList();
    double dist(Courier c) => Geo.roadKm(c.position, pickup);
    int byPriority(Courier a, Courier b) {
      final d = dist(a).compareTo(dist(b));
      if (d != 0) return d;
      // desempate: quem está livre há mais tempo
      final ia = a.idleSince ?? DateTime(2100), ib = b.idleSince ?? DateTime(2100);
      return ia.compareTo(ib);
    }

    final steps = <DispatchStep>[];
    final used = <String>{};

    final preferred = [
      for (final id in merchant.preferredCourierIds)
        ...eligible.where((c) => c.id == id && dist(c) <= rules.broadcastRadiusKm),
    ];
    for (final c in preferred) {
      steps.add(DispatchStep(courierIds: [c.id], reason: 'preferred'));
      used.add(c.id);
    }

    for (final r in rules.radiiKm) {
      final ring = eligible.where((c) => !used.contains(c.id) && dist(c) <= r).toList()..sort(byPriority);
      for (final c in ring) {
        steps.add(DispatchStep(courierIds: [c.id], reason: 'radius:${r.toStringAsFixed(0)}'));
        used.add(c.id);
      }
    }

    final broadcast = eligible.where((c) => dist(c) <= rules.broadcastRadiusKm).toList()..sort(byPriority);
    if (broadcast.isNotEmpty) {
      steps.add(DispatchStep(courierIds: [for (final c in broadcast) c.id], reason: 'broadcast'));
    }
    return steps;
  }

  /// O que fazer depois de [elapsed] sem aceite.
  DispatchDecision decide(Duration elapsed) {
    if (elapsed >= rules.giveUpAfter) return DispatchDecision.giveUp;
    if (elapsed >= rules.escalateAfter) return DispatchDecision.escalate;
    return DispatchDecision.keepTrying;
  }
}

enum DispatchDecision { keepTrying, escalate, giveUp }
