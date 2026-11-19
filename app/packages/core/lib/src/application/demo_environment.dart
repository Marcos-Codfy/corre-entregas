import 'dart:math' as math;

import '../data/in_memory.dart';
import '../data/seed.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import 'delivery_service.dart';
import 'simulator.dart';

/// Monta tudo o que o modo demonstração precisa: repositórios em memória com dados de Palmas,
/// casos de uso e simulador. Na Onda 2 este é o ponto trocado pela injeção do Supabase.
class DemoEnvironment {
  DemoEnvironment._(this.service, this.simulator, this.coupons);

  final DeliveryService service;
  final Simulator simulator;
  final CouponRepository coupons;

  DeliveryRepository get deliveries => service.deliveries;
  CourierRepository get couriers => service.couriers;
  MerchantRepository get merchants => service.merchants;
  WalletRepository get wallet => service.wallet;
  EventLog get events => service.events;
  IncidentRepository get incidents => service.incidents;

  static Future<DemoEnvironment> seeded({Clock clock = const SystemClock(), int seed = 7, double timeScale = 6, bool withHistory = true}) async {
    final service = DeliveryService(
      deliveries: InMemoryDeliveryRepository(),
      couriers: InMemoryCourierRepository(),
      merchants: InMemoryMerchantRepository(),
      wallet: InMemoryWalletRepository(),
      events: InMemoryEventLog(),
      incidents: InMemoryIncidentRepository(),
      clock: clock,
      random: math.Random(seed),
    );
    final coupons = InMemoryCouponRepository();
    final now = clock.now();

    for (final m in Seed.merchants) {
      await service.merchants.save(m);
    }
    for (final c in Seed.couriers) {
      await service.couriers.save(c.copyWith(idleSince: now.subtract(Duration(minutes: c.id.length))));
    }
    for (final c in Seed.coupons(now)) {
      await coupons.save(c);
    }
    if (withHistory) {
      for (final d in Seed.history(now: now)) {
        await service.deliveries.save(d);
        if (d.courierId != null && d.timeline.containsKey(d.status) && d.status.name == 'delivered') {
          await service.wallet.add(WalletEntry(
            id: 'w-${d.id}',
            ownerId: d.courierId!,
            amount: d.courierAmount,
            description: 'Entrega ${d.code}',
            at: d.timeline[d.status]!,
            kind: WalletEntryKind.freight,
          ));
        }
      }
      // Saques antigos do motoboy de demonstração, para o saldo ficar realista.
      final earned = service.wallet.balanceOf(Seed.demoCourierId);
      if (earned > 9650) {
        await service.wallet.add(WalletEntry(
          id: 'w-saque-demo',
          ownerId: Seed.demoCourierId,
          amount: -(earned - 9650),
          description: 'Saques Pix anteriores',
          at: now.subtract(const Duration(days: 1)),
          kind: WalletEntryKind.withdrawal,
        ));
      }
    }
    return DemoEnvironment._(service, Simulator(service, random: math.Random(seed + 1), timeScale: timeScale), coupons);
  }

  void dispose() => simulator.dispose();
}
