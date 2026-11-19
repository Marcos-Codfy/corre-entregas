import 'package:corre_core/corre_core.dart';
import 'package:test/test.dart';

class FixedClock implements Clock {
  DateTime value = DateTime(2026, 11, 19, 19, 0);
  @override
  DateTime now() => value;
  void advance(Duration d) => value = value.add(d);
}

void main() {
  late DemoEnvironment env;
  late DeliveryService s;
  late FixedClock clock;
  const customer = Customer(name: 'Mariana Silva', phone: '63988881234');
  final drop = Seed.places[2];
  const courierId = Seed.demoCourierId;
  const merchantId = Seed.demoMerchantId;

  setUp(() async {
    clock = FixedClock();
    env = await DemoEnvironment.seeded(clock: clock, withHistory: false);
    s = env.service;
    await env.couriers.save(env.couriers.byId(courierId)!.copyWith(availability: CourierAvailability.online));
  });

  tearDown(() => env.dispose());

  Future<Delivery> deliverUntil(DeliveryStatus target) async {
    var d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
    d = await s.accept(d.id, courierId);
    if (target == DeliveryStatus.accepted) return d;
    for (final st in DeliveryFlow.happyPath.skip(1)) {
      if (st == DeliveryStatus.delivered) break;
      d = await s.advance(d.id, st);
      if (st == target) break;
    }
    return d;
  }

  group('criar entrega', () {
    test('reserva o total do saldo do comércio e registra evento', () async {
      final before = env.merchants.byId(merchantId)!.balance;
      final d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop, orderValue: 4500);
      expect(env.merchants.byId(merchantId)!.balance, before - d.merchantTotal);
      expect(d.status, DeliveryStatus.searching);
      expect(d.deliveryCode, hasLength(4));
      expect(env.events.all().first.type, 'delivery.created');
      expect(env.events.all().first.data['orderValue'], 4500);
    });

    test('saldo insuficiente bloqueia e não mexe no saldo', () async {
      final m = env.merchants.byId(merchantId)!;
      await env.merchants.save(m.copyWith(balance: 100));
      await expectLater(s.create(merchantId: merchantId, customer: customer, dropoff: drop), throwsA(isA<BusinessError>()));
      expect(env.merchants.byId(merchantId)!.balance, 100);
      expect(env.deliveries.all(), isEmpty);
    });

    test('comércio em análise não pede entrega', () async {
      await expectLater(s.create(merchantId: 'merchant-distrib', customer: customer, dropoff: drop), throwsA(isA<BusinessError>()));
    });

    test('telefone incompleto é recusado', () async {
      await expectLater(
        s.create(merchantId: merchantId, customer: const Customer(name: 'X', phone: '6399'), dropoff: drop),
        throwsA(isA<BusinessError>()),
      );
    });
  });

  group('aceite', () {
    test('motoboy fica ocupado e não aceita outra ao mesmo tempo', () async {
      final a = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      final b = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      await s.accept(a.id, courierId);
      expect(env.couriers.byId(courierId)!.availability, CourierAvailability.onDelivery);
      await expectLater(s.accept(b.id, courierId), throwsA(isA<BusinessError>()));
    });

    test('dois motoboys não pegam a mesma corrida', () async {
      final a = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      await s.accept(a.id, courierId);
      await expectLater(s.accept(a.id, 'courier-rafa'), throwsA(isA<BusinessError>()));
    });

    test('desistir depois de aceitar volta a procurar e libera o motoboy', () async {
      final a = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      await s.accept(a.id, courierId);
      final back = await s.courierGiveBack(a.id, reason: 'pneu furado');
      expect(back.status, DeliveryStatus.searching);
      expect(back.courierId, isNull);
      expect(env.couriers.byId(courierId)!.isFree, isTrue);
    });
  });

  group('prova de entrega', () {
    test('código errado não conclui; código certo credita o motoboy e anonimiza o cliente', () async {
      final d = await deliverUntil(DeliveryStatus.atCustomer);
      final before = env.wallet.balanceOf(courierId);
      expect(await s.confirmCode(d.id, '0000' == d.deliveryCode ? '1111' : '0000'), isFalse);
      expect(env.deliveries.byId(d.id)!.status, DeliveryStatus.atCustomer);
      expect(await s.confirmCode(d.id, d.deliveryCode), isTrue);
      final done = env.deliveries.byId(d.id)!;
      expect(done.status, DeliveryStatus.delivered);
      expect(done.customer.phone, isEmpty);
      expect(env.wallet.balanceOf(courierId), before + d.courierAmount);
      expect(env.couriers.byId(courierId)!.isFree, isTrue);
    });

    test('aceita os 4 últimos dígitos do telefone como código padrão', () async {
      final d = await deliverUntil(DeliveryStatus.atCustomer);
      expect(await s.confirmCode(d.id, '1234'), isTrue);
      expect(env.deliveries.byId(d.id)!.usedFallbackCode, isTrue);
    });

    test('sem código: confirmação pelo comércio fica marcada para o suporte', () async {
      final d = await deliverUntil(DeliveryStatus.atCustomer);
      expect(await s.confirmCode(d.id, '', viaMerchantCall: true), isTrue);
      expect(env.events.all().any((e) => e.type == 'proof.ok' && e.data['viaMerchantCall'] == true), isTrue);
    });

    test('não confirma antes de chegar no cliente', () async {
      final d = await deliverUntil(DeliveryStatus.toCustomer);
      await expectLater(s.confirmCode(d.id, d.deliveryCode), throwsA(isA<BusinessError>()));
    });

    test('pular etapa é erro de transição', () async {
      final d = await deliverUntil(DeliveryStatus.accepted);
      await expectLater(s.advance(d.id, DeliveryStatus.toCustomer), throwsA(isA<InvalidTransition>()));
    });
  });

  group('cancelamento', () {
    test('antes do aceite: estorno total', () async {
      final before = env.merchants.byId(merchantId)!.balance;
      final d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      await s.cancel(d.id, reason: 'cliente desistiu');
      expect(env.merchants.byId(merchantId)!.balance, before);
    });

    test('aceito mas motoboy rodou menos de 1 km: grátis', () async {
      final before = env.merchants.byId(merchantId)!.balance;
      final d = await deliverUntil(DeliveryStatus.accepted);
      await env.deliveries.save(env.deliveries.byId(d.id)!.copyWith(courierTraveledKm: .6));
      final c = await s.cancel(d.id, reason: 'x');
      expect(c.cancellationFee, 0);
      expect(env.merchants.byId(merchantId)!.balance, before);
    });

    test('aceito e motoboy rodou 1 km ou mais: R\$ 3 para o motoboy', () async {
      final before = env.merchants.byId(merchantId)!.balance;
      final courierBefore = env.wallet.balanceOf(courierId);
      final d = await deliverUntil(DeliveryStatus.accepted);
      await env.deliveries.save(env.deliveries.byId(d.id)!.copyWith(courierTraveledKm: 1.2));
      final c = await s.cancel(d.id, reason: 'x');
      expect(c.cancellationFee, 300);
      expect(env.merchants.byId(merchantId)!.balance, before - 300);
      expect(env.wallet.balanceOf(courierId), courierBefore + 300);
      expect(env.couriers.byId(courierId)!.isFree, isTrue);
    });

    test('depois da coleta não cancela', () async {
      final d = await deliverUntil(DeliveryStatus.pickedUp);
      await expectLater(s.cancel(d.id, reason: 'x'), throwsA(isA<BusinessError>()));
    });
  });

  group('despacho sem aceite', () {
    test('sem motoboy: estorno total', () async {
      final before = env.merchants.byId(merchantId)!.balance;
      final d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      await s.giveUp(d.id);
      expect(env.deliveries.byId(d.id)!.status, DeliveryStatus.noCourier);
      expect(env.merchants.byId(merchantId)!.balance, before);
    });

    test('escalonamento soma R\$ 1 ao motoboy uma vez só e para no teto do mês', () async {
      final d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
      final e1 = await s.escalate(d.id);
      final e2 = await s.escalate(d.id);
      expect(e1.escalation, 100);
      expect(e2.escalation, 100, reason: 'não acumula na mesma entrega');
      for (var i = 0; i < 60; i++) {
        final x = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
        await s.escalate(x.id);
        await s.giveUp(x.id);
      }
      expect(s.escalationSpentThisMonth, 5000);
    });
  });

  group('carteira e avaliação', () {
    test('recarga mínima de R\$ 50', () async {
      await expectLater(s.topUp(merchantId, 4999), throwsA(isA<BusinessError>()));
      final before = env.merchants.byId(merchantId)!.balance;
      await s.topUp(merchantId, 5000);
      expect(env.merchants.byId(merchantId)!.balance, before + 5000);
    });

    test('saque zera o saldo e não saca sem saldo', () async {
      final d = await deliverUntil(DeliveryStatus.atCustomer);
      await s.confirmCode(d.id, d.deliveryCode);
      await s.withdraw(courierId);
      expect(env.wallet.balanceOf(courierId), 0);
      await expectLater(s.withdraw(courierId), throwsA(isA<BusinessError>()));
    });

    test('nota fora de 1 a 5 é recusada; só avalia entrega concluída', () async {
      final d = await deliverUntil(DeliveryStatus.atCustomer);
      await expectLater(s.rateCourier(d.id, 5), throwsA(isA<BusinessError>()));
      await s.confirmCode(d.id, d.deliveryCode);
      await expectLater(s.rateCourier(d.id, 0), throwsA(isA<BusinessError>()));
      await s.rateCourier(d.id, 5);
      expect(env.deliveries.byId(d.id)!.courierRating, 5);
    });
  });

  test('ocorrência crítica abre roteiro e trava a entrega em análise', () async {
    final d = await deliverUntil(DeliveryStatus.toCustomer);
    final i = await s.openIncident(d.id, IncidentKind.accident, openedBy: courierId);
    expect(i.checklist.keys, Incident.criticalScript);
    expect(env.deliveries.byId(d.id)!.status, DeliveryStatus.incident);
  });

  test('métricas batem com o histórico', () {
    final hist = Seed.history(now: DateTime(2026, 11, 19));
    final m = DeliveryMetrics.from(hist);
    expect(m.total, hist.length);
    expect(m.delivered + m.cancelled + m.returned + m.noCourier, m.total);
    expect(m.successRate, inInclusiveRange(0, 1));
    expect(m.platformRevenue, m.delivered * 150);
  });

  test('admin muda o preço: vale para a próxima entrega e valores inválidos são recusados', () async {
    expect(() => s.updatePricing(const PricingRules(baseFreight: 0), adminId: 'a'), throwsA(isA<BusinessError>()));
    s.updatePricing(const PricingRules().copyWith(platformFee: 100), adminId: 'a');
    final d = await s.create(merchantId: merchantId, customer: customer, dropoff: drop);
    expect(d.quote.platformFee, 100);
    expect(env.events.all().first.type, 'delivery.created');
    expect(env.events.all().any((e) => e.type == 'pricing.updated'), isTrue);
  });

  group('clientes frequentes', () {
    test('repetir sem confirmar o endereço é bloqueado e não cria entrega', () async {
      final saved = env.savedCustomers.list(merchantId).first;
      await expectLater(s.repeatFor(saved, addressConfirmed: false), throwsA(isA<BusinessError>()));
      expect(env.deliveries.all(), isEmpty);
    });

    test('repetir confirmado usa o mesmo endereço e soma o uso', () async {
      final saved = env.savedCustomers.list(merchantId).first;
      final d = await s.repeatFor(saved, addressConfirmed: true);
      expect(d.dropoff.line, saved.address.line);
      expect(env.savedCustomers.list(merchantId).first.timesUsed, saved.timesUsed + 1);
    });

    test('mesmo telefone atualiza o endereço em vez de duplicar', () async {
      final before = env.savedCustomers.list(merchantId).length;
      await s.create(merchantId: merchantId, customer: customer, dropoff: Seed.places[9], rememberCustomer: true);
      final list = env.savedCustomers.list(merchantId);
      expect(list, hasLength(before));
      expect(list.firstWhere((c) => c.customer.phone == customer.phone).address.line, Seed.places[9].line);
    });

    test('apagar remove da lista do comércio', () async {
      final saved = env.savedCustomers.list(merchantId).last;
      await env.savedCustomers.delete(saved.id);
      expect(env.savedCustomers.list(merchantId).map((c) => c.id), isNot(contains(saved.id)));
    });
  });
}
