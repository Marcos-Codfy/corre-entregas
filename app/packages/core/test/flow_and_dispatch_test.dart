import 'package:corre_core/corre_core.dart';
import 'package:test/test.dart';

Courier courier(String id, GeoPoint at, {double? rating = 4.8, CourierAvailability a = CourierAvailability.online, ApprovalStatus approval = ApprovalStatus.approved, DateTime? idle}) => Courier(
      id: id,
      name: id,
      phone: '63900000000',
      bikeModel: 'CG',
      position: at,
      rating: rating,
      availability: a,
      approval: approval,
      idleSince: idle,
    );

void main() {
  group('máquina de estados', () {
    test('caminho feliz é todo permitido', () {
      final path = [DeliveryStatus.searching, ...DeliveryFlow.happyPath];
      for (var i = 0; i < path.length - 1; i++) {
        expect(DeliveryFlow.canTransition(path[i], path[i + 1]), isTrue, reason: '${path[i]} → ${path[i + 1]}');
      }
    });

    test('estados finais não saem para lugar nenhum', () {
      for (final s in DeliveryStatus.values.where((s) => s.isFinal)) {
        expect(DeliveryFlow.nextOf(s), isEmpty, reason: s.name);
      }
    });

    test('não pula etapas nem volta depois da coleta', () {
      expect(DeliveryFlow.canTransition(DeliveryStatus.searching, DeliveryStatus.delivered), isFalse);
      expect(DeliveryFlow.canTransition(DeliveryStatus.accepted, DeliveryStatus.toCustomer), isFalse);
      expect(DeliveryFlow.canTransition(DeliveryStatus.pickedUp, DeliveryStatus.cancelledByMerchant), isFalse);
      expect(DeliveryFlow.canTransition(DeliveryStatus.toCustomer, DeliveryStatus.searching), isFalse);
    });

    test('todo estado não final tem saída (nenhuma entrega fica presa)', () {
      for (final s in DeliveryStatus.values.where((s) => !s.isFinal)) {
        expect(DeliveryFlow.nextOf(s), isNotEmpty, reason: s.name);
      }
    });

    test('comércio só cancela antes da coleta', () {
      expect(DeliveryStatus.atMerchant.merchantCanCancel, isTrue);
      expect(DeliveryStatus.pickedUp.merchantCanCancel, isFalse);
    });
  });

  group('despacho', () {
    const pickup = GeoPoint(-10.19, -48.33);
    final merchant = Merchant(
      id: 'm',
      name: 'M',
      category: 'x',
      address: const Address(line: 'a', district: 'b', point: pickup),
      preferredCourierIds: const ['far-pref', 'pref', 'pref-offline'],
    );
    const planner = DispatchPlanner();

    GeoPoint at(double km) => GeoPoint(pickup.lat + km / 111 / Geo.roadFactor, pickup.lng);

    test('elegibilidade: nota mínima 4,0, aprovado, livre e documentos em dia', () {
      expect(planner.isEligible(courier('a', pickup)), isTrue);
      expect(planner.isEligible(courier('a', pickup, rating: 4.0)), isTrue);
      expect(planner.isEligible(courier('a', pickup, rating: 3.99)), isFalse);
      expect(planner.isEligible(courier('a', pickup, rating: null)), isTrue, reason: 'novato sem nota recebe');
      expect(planner.isEligible(courier('a', pickup, a: CourierAvailability.onDelivery)), isFalse);
      expect(planner.isEligible(courier('a', pickup, a: CourierAvailability.offline)), isFalse);
      expect(planner.isEligible(courier('a', pickup, approval: ApprovalStatus.pending)), isFalse);
      final expired = courier('a', pickup).copyWith(documents: {DocumentKind.cnh: ApprovalStatus.rejected});
      expect(planner.isEligible(expired), isFalse);
    });

    test('ordem: preferidos → raio 5 km → raio 7 km → broadcast 10 km', () {
      final steps = planner.plan(merchant: merchant, couriers: [
        courier('near', at(1)),
        courier('mid', at(6)),
        courier('pref', at(4)),
        courier('far-pref', at(9)),
        courier('pref-offline', at(1), a: CourierAvailability.offline),
        courier('out', at(12)),
        courier('bad', at(.5), rating: 3.5),
      ]);
      expect(steps.map((s) => s.reason).toList(), ['preferred', 'preferred', 'radius:5', 'radius:7', 'broadcast']);
      expect(steps[0].courierIds, ['far-pref'], reason: 'respeita a ordem dos preferidos do comércio');
      expect(steps[1].courierIds, ['pref']);
      expect(steps[2].courierIds, ['near']);
      expect(steps[3].courierIds, ['mid']);
      expect(steps.last.courierIds.toSet(), {'near', 'mid', 'pref', 'far-pref'});
      final everyone = steps.expand((s) => s.courierIds).toSet();
      expect(everyone, isNot(contains('out')), reason: 'fora de 10 km');
      expect(everyone, isNot(contains('bad')), reason: 'nota abaixo de 4,0');
      expect(everyone, isNot(contains('pref-offline')));
    });

    test('empate de distância: quem está livre há mais tempo vem primeiro', () {
      final steps = planner.plan(merchant: merchant.copyWith(preferredCourierIds: const []), couriers: [
        courier('recent', at(2), idle: DateTime(2026, 1, 1, 12)),
        courier('waiting', at(2), idle: DateTime(2026, 1, 1, 11)),
      ]);
      expect(steps.first.courierIds, ['waiting']);
    });

    test('exclui quem já recusou', () {
      final steps = planner.plan(merchant: merchant, couriers: [courier('near', at(1))], exclude: {'near'});
      expect(steps, isEmpty);
    });

    test('20 s por oferta; escala com 5 min e desiste com 10 min', () {
      expect(planner.rules.offerTimeout, const Duration(seconds: 20));
      expect(planner.decide(const Duration(minutes: 4, seconds: 59)), DispatchDecision.keepTrying);
      expect(planner.decide(const Duration(minutes: 5)), DispatchDecision.escalate);
      expect(planner.decide(const Duration(minutes: 10)), DispatchDecision.giveUp);
    });

    test('comércio não pode ter mais de 3 preferidos', () {
      expect(() => merchant.copyWith(preferredCourierIds: ['a', 'b', 'c', 'd']), throwsArgumentError);
    });
  });

  group('geo', () {
    test('distância de rua = linha reta × 1,3 e é simétrica', () {
      const a = GeoPoint(-10.18, -48.33), b = GeoPoint(-10.20, -48.32);
      expect(Geo.roadKm(a, b), closeTo(Geo.straightKm(a, b) * 1.3, 1e-9));
      expect(Geo.straightKm(a, b), closeTo(Geo.straightKm(b, a), 1e-9));
      expect(Geo.straightKm(a, a), 0);
    });

    test('ponto no caminho fica entre as pontas', () {
      const a = GeoPoint(0, 0), b = GeoPoint(1, 1);
      expect(Geo.alongPath(Geo.manhattanPath(a, b), 0), a);
      final end = Geo.alongPath(Geo.manhattanPath(a, b), 1);
      expect(end.lat, closeTo(1, 1e-9));
      expect(end.lng, closeTo(1, 1e-9));
      expect(Geo.lerp(a, b, 2), b, reason: 'limita em 1');
    });
  });

  test('código padrão = 4 últimos dígitos do telefone; anonimização apaga dados', () {
    const c = Customer(name: 'Mariana Silva', phone: '63988881234');
    expect(c.fallbackCode, '1234');
    expect(c.firstName, 'Mariana');
    expect(c.anonymized().phone, isEmpty);
    expect(c.anonymized().name, isNot(contains('Mariana')));
  });
}
