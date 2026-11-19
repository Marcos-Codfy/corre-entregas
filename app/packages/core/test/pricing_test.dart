import 'package:corre_core/corre_core.dart';
import 'package:test/test.dart';

void main() {
  const p = PricingService();

  group('frete', () {
    test('até 5 km paga só a base de R\$ 8', () {
      expect(p.freightFor(0), 800);
      expect(p.freightFor(2.1), 800);
      expect(p.freightFor(5), 800, reason: 'exatamente 5 km ainda é base');
    });

    test('acima de 5 km soma R\$ 1,50 por km, arredondando para cima em 0,5 km', () {
      expect(p.freightFor(5.01), 875, reason: '0,01 km extra vira 0,5 km');
      expect(p.freightFor(5.5), 875);
      expect(p.freightFor(5.51), 950);
      expect(p.freightFor(6), 950, reason: 'entrega média de 6 km = R\$ 9,50');
      expect(p.freightFor(10), 1550);
    });

    test('distância negativa é erro', () {
      expect(() => p.freightFor(-1), throwsArgumentError);
    });

    test('frete nunca diminui quando a distância aumenta', () {
      var last = 0;
      for (var km = 0.0; km <= 15; km += .05) {
        final f = p.freightFor(km);
        expect(f, greaterThanOrEqualTo(last), reason: 'km=$km');
        last = f;
      }
    });
  });

  group('cotação', () {
    test('comércio paga frete + taxa; motoboy fica com 100% do frete', () {
      final q = p.quote(6);
      expect(q.courierAmount, 950);
      expect(q.platformFee, 150);
      expect(q.merchantTotal, 1100);
    });

    test('parada extra e chuva entram para o motoboy, não para a plataforma', () {
      final q = p.quote(3, extraStops: 1, rainOrLateNight: true);
      expect(q.extras, 500);
      expect(q.courierAmount, 1300);
      expect(q.platformFee, 150);
    });

    test('número de paradas negativo é erro', () {
      expect(() => p.quote(3, extraStops: -1), throwsArgumentError);
    });
  });

  group('adicionais e cancelamento', () {
    test('espera: grátis até 10 min, depois R\$ 1 a cada 10 min', () {
      expect(p.waitFee(0), 0);
      expect(p.waitFee(10), 0);
      expect(p.waitFee(11), 100);
      expect(p.waitFee(20), 100);
      expect(p.waitFee(21), 200);
    });

    test('retorno paga 50% do frete', () => expect(p.returnFee(950), 475));

    test('cancelar antes do aceite é grátis', () {
      expect(p.cancellationFee(accepted: false, courierTraveledKm: 3), 0);
    });

    test('depois do aceite só cobra R\$ 3 se o motoboy já rodou 1 km', () {
      expect(p.cancellationFee(accepted: true, courierTraveledKm: .99), 0);
      expect(p.cancellationFee(accepted: true, courierTraveledKm: 1), 300);
    });

    test('escalonamento respeita o teto de R\$ 50 no mês', () {
      expect(p.escalationAvailable(0), 100);
      expect(p.escalationAvailable(4950), 50, reason: 'só o que sobra do teto');
      expect(p.escalationAvailable(5000), 0);
      expect(p.escalationAvailable(7000), 0);
    });
  });

  test('formatCents', () {
    expect(formatCents(950), 'R\$ 9,50');
    expect(formatCents(0), 'R\$ 0,00');
    expect(formatCents(123456), 'R\$ 1.234,56');
    expect(formatCents(-300), '−R\$ 3,00');
  });

  test('copyWith troca só o que foi pedido', () {
    final r = const PricingRules().copyWith(baseFreight: 900);
    expect(r.baseFreight, 900);
    expect(r.perExtraKm, 150);
    expect(PricingService(r).freightFor(6), 1050);
  });
}
