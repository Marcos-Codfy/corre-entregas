import 'dart:math' as math;

import '../domain/delivery_status.dart';
import '../domain/entities.dart';
import '../domain/geo.dart';
import '../domain/pricing.dart';

/// Dados fictícios de Palmas-TO para o modo demonstração.
/// Coordenadas aproximadas das quadras; nomes e telefones são inventados.
abstract final class Seed {
  static const demoCourierId = 'courier-demo';
  static const demoMerchantId = 'merchant-burger106';
  static const supportUserId = 'user-support';
  static const adminUserId = 'user-admin';

  static const places = <Address>[
    Address(line: 'Qd. 104 Sul, Av. LO-1, lote 12', district: 'Plano Diretor Sul', point: GeoPoint(-10.1889, -48.3303)),
    Address(line: 'Qd. 106 Sul, Al. 5, lote 3', district: 'Plano Diretor Sul', point: GeoPoint(-10.1912, -48.3271)),
    Address(line: 'Qd. 208 Sul, Al. 12, lote 7', district: 'Plano Diretor Sul', point: GeoPoint(-10.1985, -48.3239)),
    Address(line: 'Qd. 307 Sul, Al. 3, lote 20', district: 'Plano Diretor Sul', point: GeoPoint(-10.2052, -48.3181)),
    Address(line: 'Qd. 405 Sul, Al. 9, lote 14', district: 'Plano Diretor Sul', point: GeoPoint(-10.2128, -48.3147)),
    Address(line: 'Qd. 1106 Sul, Al. 20, lote 2', district: 'Plano Diretor Sul', point: GeoPoint(-10.2310, -48.3315)),
    Address(line: 'Qd. 104 Norte, Rua NE-5, lote 8', district: 'Plano Diretor Norte', point: GeoPoint(-10.1755, -48.3311)),
    Address(line: 'Qd. 204 Norte, Al. 8, lote 31', district: 'Plano Diretor Norte', point: GeoPoint(-10.1697, -48.3248)),
    Address(line: 'Qd. 405 Norte, Al. 15, lote 4', district: 'Plano Diretor Norte', point: GeoPoint(-10.1613, -48.3122)),
    Address(line: 'Qd. 603 Norte, Al. 2, lote 9', district: 'Plano Diretor Norte', point: GeoPoint(-10.1525, -48.3165)),
    Address(line: 'Av. Teotônio Segurado, 1501', district: 'Centro', point: GeoPoint(-10.1931, -48.3352)),
    Address(line: 'Rua 7, Qd. 15, lote 3', district: 'Taquaralto', point: GeoPoint(-10.2832, -48.3189)),
    Address(line: 'Qd. ARSE 51, Al. 4, lote 11', district: 'Plano Diretor Sul', point: GeoPoint(-10.2015, -48.3140)),
    Address(line: 'Qd. ARNE 51, Al. 10, lote 6', district: 'Plano Diretor Norte', point: GeoPoint(-10.1689, -48.3127)),
    Address(line: 'Orla da Praia da Graciosa, quiosque 4', district: 'Graciosa', point: GeoPoint(-10.1853, -48.3622)),
  ];

  static final merchants = <Merchant>[
    Merchant(id: demoMerchantId, name: 'Burger da 106', category: 'Lanchonete', cnpj: '12.345.678/0001-90', phone: '63992140106', balance: 13240, preferredCourierIds: const [demoCourierId, 'courier-rafa', 'courier-lucas'], address: const Address(line: 'Qd. 106 Sul, Av. NS-2, lote 1', district: 'Plano Diretor Sul', point: GeoPoint(-10.1918, -48.3258))),
    const Merchant(id: 'merchant-farmavida', name: 'Farmácia Vida', category: 'Farmácia', balance: 25000, address: Address(line: 'Qd. 204 Sul, Av. LO-5, lote 4', district: 'Plano Diretor Sul', point: GeoPoint(-10.1960, -48.3301))),
    const Merchant(id: 'merchant-acai', name: 'Açaí da Praia', category: 'Açaí', balance: 8000, address: Address(line: 'Qd. 103 Norte, Av. JK, lote 22', district: 'Plano Diretor Norte', point: GeoPoint(-10.1781, -48.3336))),
    const Merchant(id: 'merchant-pizza', name: 'Pizzaria Girassol', category: 'Pizzaria', balance: 41000, address: Address(line: 'Qd. 304 Sul, Al. 2, lote 1', district: 'Plano Diretor Sul', point: GeoPoint(-10.2030, -48.3262))),
    const Merchant(id: 'merchant-sushi', name: 'Sushi Capim Dourado', category: 'Restaurante', balance: 17500, address: Address(line: 'Qd. 202 Norte, Av. LO-4, lote 9', district: 'Plano Diretor Norte', point: GeoPoint(-10.1718, -48.3290))),
    const Merchant(id: 'merchant-distrib', name: 'Distribuidora Jalapão', category: 'Bebidas', balance: 6000, approval: ApprovalStatus.pending, address: Address(line: 'Rua 12, Qd. 30, lote 5', district: 'Taquaralto', point: GeoPoint(-10.2801, -48.3205))),
  ];

  static final couriers = <Courier>[
    Courier(id: demoCourierId, name: 'Diego Martins', phone: '63991110001', bikeModel: 'Honda CG 160', rating: 4.9, ratingCount: 212, position: const GeoPoint(-10.1902, -48.3285), pixKey: '***.482.***-10', documents: _docs()),
    Courier(id: 'courier-rafa', name: 'Rafael Souza', phone: '63991110002', bikeModel: 'Yamaha Factor 150', rating: 4.8, ratingCount: 133, availability: CourierAvailability.online, position: const GeoPoint(-10.1970, -48.3220), documents: _docs()),
    Courier(id: 'courier-lucas', name: 'Lucas Pereira', phone: '63991110003', bikeModel: 'Honda Fan 160', rating: 4.7, ratingCount: 89, availability: CourierAvailability.online, position: const GeoPoint(-10.1760, -48.3330), documents: _docs()),
    Courier(id: 'courier-ana', name: 'Ana Ribeiro', phone: '63991110004', bikeModel: 'Honda Pop 110i', rating: 4.95, ratingCount: 61, availability: CourierAvailability.online, position: const GeoPoint(-10.2080, -48.3170), documents: _docs()),
    Courier(id: 'courier-joao', name: 'João Batista', phone: '63991110005', bikeModel: 'Honda CG 160', rating: 4.2, ratingCount: 40, availability: CourierAvailability.online, position: const GeoPoint(-10.1655, -48.3200), documents: _docs()),
    Courier(id: 'courier-marcos', name: 'Marcos Lima', phone: '63991110006', bikeModel: 'Yamaha Fazer 250', rating: 3.8, ratingCount: 35, availability: CourierAvailability.online, position: const GeoPoint(-10.1890, -48.3400), documents: _docs()),
    Courier(id: 'courier-bia', name: 'Beatriz Costa', phone: '63991110007', bikeModel: 'Honda Biz 125', availability: CourierAvailability.offline, position: const GeoPoint(-10.2300, -48.3300), documents: _docs()),
    Courier(id: 'courier-paulo', name: 'Paulo Henrique', phone: '63991110008', bikeModel: 'Honda CG 160', approval: ApprovalStatus.pending, position: const GeoPoint(-10.2000, -48.3300), documents: {
      DocumentKind.cnh: ApprovalStatus.pending,
      DocumentKind.crlv: ApprovalStatus.approved,
      DocumentKind.selfie: ApprovalStatus.pending,
      DocumentKind.background: ApprovalStatus.pending,
      DocumentKind.pixKey: ApprovalStatus.approved,
    }),
    Courier(id: 'courier-tiago', name: 'Tiago Alves', phone: '63991110009', bikeModel: 'Yamaha Factor 150', approval: ApprovalStatus.pending, position: const GeoPoint(-10.1700, -48.3300), documents: {
      for (final k in DocumentKind.values) k: ApprovalStatus.pending,
    }),
  ];

  static Map<DocumentKind, ApprovalStatus> _docs() => {for (final k in DocumentKind.values) k: ApprovalStatus.approved};

  static const _names = ['Mariana Silva', 'João Pedro', 'Bia Santos', 'Carlos Eduardo', 'Rita Moreira', 'Paulo Vitor', 'Ana Clara', 'Felipe Rocha', 'Júlia Neves', 'Gustavo Melo'];

  static Customer randomCustomer(math.Random r) {
    final n = _names[r.nextInt(_names.length)];
    return Customer(name: n, phone: '639${8000 + r.nextInt(1999)}${1000 + r.nextInt(8999)}');
  }

  /// Histórico de entregas dos últimos [days] dias para relatórios e painel.
  static List<Delivery> history({required DateTime now, int days = 14, int seed = 42}) {
    final r = math.Random(seed);
    const pricing = PricingService();
    final approved = merchants.where((m) => m.approval == ApprovalStatus.approved).toList();
    final active = couriers.where((c) => c.approval == ApprovalStatus.approved).toList();
    final list = <Delivery>[];
    var seq = 4000;
    for (var day = days; day >= 1; day--) {
      final count = 6 + r.nextInt(10);
      for (var i = 0; i < count; i++) {
        final m = approved[r.nextInt(approved.length)];
        final drop = places[r.nextInt(places.length)];
        final km = Geo.roadKm(m.address.point, drop.point);
        final rain = r.nextDouble() < .08;
        final q = pricing.quote(km, rainOrLateNight: rain);
        final created = DateTime(now.year, now.month, now.day - day, 11 + r.nextInt(12), r.nextInt(60));
        final roll = r.nextDouble();
        final status = roll < .88
            ? DeliveryStatus.delivered
            : roll < .94
                ? DeliveryStatus.cancelledByMerchant
                : roll < .97
                    ? DeliveryStatus.returned
                    : DeliveryStatus.noCourier;
        final courier = status == DeliveryStatus.noCourier ? null : active[r.nextInt(active.length)];
        final accept = created.add(Duration(seconds: 15 + r.nextInt(200)));
        final pick = accept.add(Duration(minutes: 5 + r.nextInt(12)));
        final done = pick.add(Duration(minutes: Geo.etaMinutes(km) + r.nextInt(8)));
        list.add(Delivery(
          id: 'hist-${seq + 1}',
          code: '#PL-${++seq}',
          merchantId: m.id,
          customer: const Customer(name: 'Cliente', phone: ''),
          pickup: m.address,
          dropoff: drop,
          quote: q,
          deliveryCode: '0000',
          trackingToken: 'hist$seq',
          createdAt: created,
          status: status,
          courierId: courier?.id,
          courierTraveledKm: status == DeliveryStatus.delivered ? km : 0,
          orderValue: 2500 + r.nextInt(9000),
          courierRating: status == DeliveryStatus.delivered && r.nextBool() ? 4 + r.nextInt(2) : null,
          timeline: {
            DeliveryStatus.searching: created,
            if (courier != null) DeliveryStatus.accepted: accept,
            if (status == DeliveryStatus.delivered || status == DeliveryStatus.returned) DeliveryStatus.pickedUp: pick,
            status: status == DeliveryStatus.cancelledByMerchant ? accept : (status == DeliveryStatus.noCourier ? created.add(const Duration(minutes: 10)) : done),
          },
        ));
      }
    }
    return list;
  }

  static List<Coupon> coupons(DateTime now) => [
        Coupon(code: 'BEMVINDO10', kind: CouponKind.feeWaiver, value: 10, validUntil: now.add(const Duration(days: 60)), maxUses: 50, used: 7),
        Coupon(code: 'VEMDA99', kind: CouponKind.feeWaiver, value: 15, validUntil: now.add(const Duration(days: 30)), maxUses: 30, used: 2),
        Coupon(code: 'INDICA20', kind: CouponKind.feeWaiver, value: 20, validUntil: now.add(const Duration(days: 90)), maxUses: 100, used: 4),
        Coupon(code: 'TAXA050', kind: CouponKind.feeDiscount, value: 50, validUntil: now.subtract(const Duration(days: 3)), maxUses: 40, used: 40, active: false),
      ];
}
