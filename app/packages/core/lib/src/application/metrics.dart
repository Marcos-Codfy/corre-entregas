import 'package:meta/meta.dart';

import '../domain/delivery_status.dart';
import '../domain/entities.dart';
import '../domain/pricing.dart';

/// Indicadores calculados a partir das entregas (painel do admin e relatórios do comércio).
@immutable
class DeliveryMetrics {
  const DeliveryMetrics({
    required this.total,
    required this.delivered,
    required this.cancelled,
    required this.noCourier,
    required this.returned,
    required this.acceptedWithin5MinRate,
    required this.avgSecondsToAccept,
    required this.avgMinutesTotal,
    required this.platformRevenue,
    required this.courierEarnings,
    required this.avgOrderValue,
    required this.byMerchant,
    required this.byHour,
  });

  final int total, delivered, cancelled, noCourier, returned;

  /// Fração (0 a 1) das entregas aceitas em até 5 minutos.
  final double acceptedWithin5MinRate;
  final double avgSecondsToAccept, avgMinutesTotal;
  final Cents platformRevenue, courierEarnings;

  /// Ticket médio informado pelos comércios.
  final Cents avgOrderValue;
  final Map<String, int> byMerchant;

  /// Entregas por hora do dia (0–23).
  final Map<int, int> byHour;

  double get successRate => total == 0 ? 0 : delivered / total;

  static DeliveryMetrics from(Iterable<Delivery> all) {
    final list = all.toList();
    final delivered = list.where((d) => d.status == DeliveryStatus.delivered).toList();
    final accepted = list.where((d) => d.timeline.containsKey(DeliveryStatus.accepted)).toList();
    final acceptSecs = [
      for (final d in accepted) d.timeline[DeliveryStatus.accepted]!.difference(d.createdAt).inSeconds,
    ];
    final totals = [
      for (final d in delivered)
        if (d.timeline[DeliveryStatus.delivered] != null) d.timeline[DeliveryStatus.delivered]!.difference(d.createdAt).inMinutes,
    ];
    final orders = [for (final d in list) ?d.orderValue];
    double avg(List<num> xs) => xs.isEmpty ? 0 : xs.fold<num>(0, (s, x) => s + x) / xs.length;

    final byMerchant = <String, int>{};
    final byHour = <int, int>{};
    for (final d in list) {
      byMerchant[d.merchantId] = (byMerchant[d.merchantId] ?? 0) + 1;
      byHour[d.createdAt.hour] = (byHour[d.createdAt.hour] ?? 0) + 1;
    }
    final searchedEnough = list.where((d) => d.status != DeliveryStatus.searching).length;

    return DeliveryMetrics(
      total: list.length,
      delivered: delivered.length,
      cancelled: list.where((d) => d.status == DeliveryStatus.cancelledByMerchant).length,
      noCourier: list.where((d) => d.status == DeliveryStatus.noCourier).length,
      returned: list.where((d) => d.status == DeliveryStatus.returned).length,
      acceptedWithin5MinRate: searchedEnough == 0 ? 0 : acceptSecs.where((s) => s <= 300).length / searchedEnough,
      avgSecondsToAccept: avg(acceptSecs),
      avgMinutesTotal: avg(totals),
      platformRevenue: delivered.fold(0, (s, d) => s + d.quote.platformFee),
      courierEarnings: delivered.fold(0, (s, d) => s + d.courierAmount),
      avgOrderValue: avg(orders).round(),
      byMerchant: byMerchant,
      byHour: byHour,
    );
  }
}
