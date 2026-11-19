import 'package:meta/meta.dart';

import 'delivery_status.dart';
import 'geo.dart';
import 'pricing.dart';

/// Endereço com descrição legível (padrão de Palmas: quadra, alameda, lote).
@immutable
class Address {
  const Address({required this.line, required this.district, required this.point, this.reference});
  final String line, district;
  final String? reference;
  final GeoPoint point;

  String get short => '$line · $district';
}

/// Cliente final. Só nome e telefone; anonimizados depois da entrega (LGPD).
@immutable
class Customer {
  const Customer({required this.name, required this.phone});
  final String name;

  /// Só dígitos, com DDD.
  final String phone;

  /// Código padrão quando o comércio não envia o link: 4 últimos dígitos do telefone.
  String get fallbackCode => phone.length >= 4 ? phone.substring(phone.length - 4) : phone.padLeft(4, '0');

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Customer anonymized() => const Customer(name: 'Cliente', phone: '');
}

enum ApprovalStatus {
  pending('Em análise'),
  approved('Aprovado'),
  rejected('Recusado');

  const ApprovalStatus(this.label);
  final String label;
}

enum CourierAvailability { offline, online, onDelivery }

enum DocumentKind {
  cnh('CNH A definitiva com EAR'),
  crlv('CRLV da moto'),
  selfie('Selfie com a CNH'),
  background('Antecedentes criminais'),
  pixKey('Chave Pix');

  const DocumentKind(this.label);
  final String label;
}

/// Motoboy autônomo (MEI ou pessoa física).
@immutable
class Courier {
  const Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.bikeModel,
    required this.position,
    this.rating,
    this.ratingCount = 0,
    this.availability = CourierAvailability.offline,
    this.approval = ApprovalStatus.approved,
    this.documents = const {},
    this.idleSince,
    this.pixKey = '',
    this.birthYear = 1998,
  });

  final String id, name, phone, bikeModel, pixKey;

  /// Média das últimas 30 avaliações; nula até ter 5.
  final double? rating;
  final int ratingCount, birthYear;
  final CourierAvailability availability;
  final ApprovalStatus approval;
  final Map<DocumentKind, ApprovalStatus> documents;
  final GeoPoint position;

  /// Desde quando está livre (desempate do despacho: quem espera há mais tempo).
  final DateTime? idleSince;

  bool get isOnline => availability != CourierAvailability.offline;
  bool get isFree => availability == CourierAvailability.online;
  String get firstName => name.split(' ').first;

  Courier copyWith({
    CourierAvailability? availability,
    GeoPoint? position,
    double? rating,
    int? ratingCount,
    ApprovalStatus? approval,
    Map<DocumentKind, ApprovalStatus>? documents,
    DateTime? idleSince,
    String? bikeModel,
  }) =>
      Courier(
        id: id,
        name: name,
        phone: phone,
        bikeModel: bikeModel ?? this.bikeModel,
        position: position ?? this.position,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        availability: availability ?? this.availability,
        approval: approval ?? this.approval,
        documents: documents ?? this.documents,
        idleSince: idleSince ?? this.idleSince,
        pixKey: pixKey,
        birthYear: birthYear,
      );
}

enum MerchantPlan {
  payPerUse('Avulso'),
  partner('Parceiro');

  const MerchantPlan(this.label);
  final String label;
}

/// Comércio que pede entregas.
@immutable
class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.balance = 0,
    this.preferredCourierIds = const [],
    this.plan = MerchantPlan.payPerUse,
    this.approval = ApprovalStatus.approved,
    this.cnpj = '',
    this.phone = '',
  });

  static const maxPreferred = 3;

  final String id, name, category, cnpj, phone;
  final Address address;

  /// Saldo pré-pago em centavos.
  final Cents balance;
  final List<String> preferredCourierIds;
  final MerchantPlan plan;
  final ApprovalStatus approval;

  Merchant copyWith({Cents? balance, List<String>? preferredCourierIds, MerchantPlan? plan, ApprovalStatus? approval}) {
    final pref = preferredCourierIds ?? this.preferredCourierIds;
    if (pref.length > maxPreferred) {
      throw ArgumentError('No máximo $maxPreferred motoboys preferidos');
    }
    return Merchant(
      id: id,
      name: name,
      category: category,
      address: address,
      balance: balance ?? this.balance,
      preferredCourierIds: pref,
      plan: plan ?? this.plan,
      approval: approval ?? this.approval,
      cnpj: cnpj,
      phone: phone,
    );
  }
}

/// Uma entrega pedida por um comércio.
@immutable
class Delivery {
  const Delivery({
    required this.id,
    required this.code,
    required this.merchantId,
    required this.customer,
    required this.pickup,
    required this.dropoff,
    required this.quote,
    required this.deliveryCode,
    required this.trackingToken,
    required this.createdAt,
    this.status = DeliveryStatus.searching,
    this.courierId,
    this.timeline = const {},
    this.notes = '',
    this.tags = const [],
    this.courierTraveledKm = 0,
    this.escalation = 0,
    this.offeredTo = const [],
    this.cancellationFee = 0,
    this.orderValue,
    this.courierRating,
    this.usedFallbackCode = false,
  });

  final String id, code, merchantId, deliveryCode, trackingToken, notes;
  final String? courierId;
  final Customer customer;
  final Address pickup, dropoff;
  final Quote quote;
  final DeliveryStatus status;
  final DateTime createdAt;
  final Map<DeliveryStatus, DateTime> timeline;
  final List<String> tags, offeredTo;
  final double courierTraveledKm;

  /// Aumento de frete por falta de aceite (pago pela plataforma).
  final Cents escalation;
  final Cents cancellationFee;

  /// Valor do pedido informado pelo comércio (só para relatório e ticket médio).
  final Cents? orderValue;
  final int? courierRating;
  final bool usedFallbackCode;

  Cents get courierAmount => quote.courierAmount + escalation;
  Cents get merchantTotal => quote.merchantTotal;

  Delivery copyWith({
    DeliveryStatus? status,
    String? courierId,
    bool clearCourier = false,
    Map<DeliveryStatus, DateTime>? timeline,
    double? courierTraveledKm,
    Cents? escalation,
    List<String>? offeredTo,
    Cents? cancellationFee,
    Customer? customer,
    int? courierRating,
    bool? usedFallbackCode,
  }) =>
      Delivery(
        id: id,
        code: code,
        merchantId: merchantId,
        customer: customer ?? this.customer,
        pickup: pickup,
        dropoff: dropoff,
        quote: quote,
        deliveryCode: deliveryCode,
        trackingToken: trackingToken,
        createdAt: createdAt,
        status: status ?? this.status,
        courierId: clearCourier ? null : (courierId ?? this.courierId),
        timeline: timeline ?? this.timeline,
        notes: notes,
        tags: tags,
        courierTraveledKm: courierTraveledKm ?? this.courierTraveledKm,
        escalation: escalation ?? this.escalation,
        offeredTo: offeredTo ?? this.offeredTo,
        cancellationFee: cancellationFee ?? this.cancellationFee,
        orderValue: orderValue,
        courierRating: courierRating ?? this.courierRating,
        usedFallbackCode: usedFallbackCode ?? this.usedFallbackCode,
      );

  /// Aplica uma transição validada pela máquina de estados.
  Delivery transition(DeliveryStatus to, DateTime at) {
    if (!DeliveryFlow.canTransition(status, to)) throw InvalidTransition(status, to);
    return copyWith(status: to, timeline: {...timeline, to: at});
  }
}

enum WalletEntryKind { freight, withdrawal, topUp, fee, refund, adjustment }

/// Lançamento na carteira (motoboy ou comércio).
@immutable
class WalletEntry {
  const WalletEntry({required this.id, required this.ownerId, required this.amount, required this.description, required this.at, required this.kind});
  final String id, ownerId, description;
  final Cents amount;
  final DateTime at;
  final WalletEntryKind kind;
}

enum CouponKind {
  feeWaiver('Entregas sem taxa'),
  feeDiscount('Desconto na taxa');

  const CouponKind(this.label);
  final String label;
}

/// Cupom criado pelo admin a qualquer momento.
@immutable
class Coupon {
  const Coupon({
    required this.code,
    required this.kind,
    required this.value,
    required this.validUntil,
    this.maxUses = 100,
    this.used = 0,
    this.merchantIds = const [],
    this.active = true,
  });

  final String code;
  final CouponKind kind;

  /// feeWaiver: quantidade de entregas; feeDiscount: centavos de desconto.
  final int value;
  final DateTime validUntil;
  final int maxUses, used;

  /// Vazio = vale para todos os comércios.
  final List<String> merchantIds;
  final bool active;

  bool isValidFor(String merchantId, DateTime now) =>
      active && used < maxUses && !now.isAfter(validUntil) && (merchantIds.isEmpty || merchantIds.contains(merchantId));

  Coupon copyWith({int? used, bool? active}) => Coupon(
        code: code,
        kind: kind,
        value: value,
        validUntil: validUntil,
        maxUses: maxUses,
        used: used ?? this.used,
        merchantIds: merchantIds,
        active: active ?? this.active,
      );
}

enum IncidentKind {
  accident('Acidente', critical: true),
  damagedOrder('Pedido avariado', critical: true),
  wrongCharge('Cobrança divergente', critical: true),
  wrongAddress('Endereço errado'),
  customerUnreachable('Cliente não atende'),
  merchantDelay('Demora no comércio'),
  other('Outro');

  const IncidentKind(this.label, {this.critical = false});
  final String label;
  final bool critical;
}

enum IncidentStatus { open, inProgress, resolved }

/// Ocorrência registrada pelo motoboy, comércio ou suporte.
@immutable
class Incident {
  const Incident({
    required this.id,
    required this.deliveryId,
    required this.kind,
    required this.openedAt,
    required this.openedBy,
    this.description = '',
    this.status = IncidentStatus.open,
    this.checklist = const {},
    this.resolution,
  });

  final String id, deliveryId, openedBy, description;
  final IncidentKind kind;
  final DateTime openedAt;
  final IncidentStatus status;

  /// Passos do roteiro de atendimento → feito ou não.
  final Map<String, bool> checklist;
  final String? resolution;

  /// Roteiro padrão para ocorrências críticas (decisão sempre com os dois sócios).
  static const criticalScript = [
    'Confirmar que todos estão em segurança (ligar para o motoboy)',
    'Registrar evidências: fotos, local, horário e relato das partes',
    'Avisar o comércio e combinar o que fazer com o pedido',
    'Bloquear o repasse desta entrega até resolver',
    'Decidir com os dois sócios e registrar a decisão',
    'Responder às partes em até 48 h',
  ];

  Incident copyWith({IncidentStatus? status, Map<String, bool>? checklist, String? resolution}) => Incident(
        id: id,
        deliveryId: deliveryId,
        kind: kind,
        openedAt: openedAt,
        openedBy: openedBy,
        description: description,
        status: status ?? this.status,
        checklist: checklist ?? this.checklist,
        resolution: resolution ?? this.resolution,
      );
}

/// Registro de tudo o que acontece (auditoria, métricas e dados para análise futura).
@immutable
class DomainEvent {
  const DomainEvent({required this.type, required this.at, this.actorId, this.deliveryId, this.position, this.data = const {}});
  final String type;
  final DateTime at;
  final String? actorId, deliveryId;
  final GeoPoint? position;
  final Map<String, Object?> data;
}

/// Cliente salvo pelo comércio para repetir pedidos (dado do comércio, que ele pode apagar).
@immutable
class SavedCustomer {
  const SavedCustomer({
    required this.id,
    required this.merchantId,
    required this.customer,
    required this.address,
    required this.lastUsed,
    this.timesUsed = 1,
    this.notes = '',
  });

  final String id, merchantId, notes;
  final Customer customer;
  final Address address;
  final DateTime lastUsed;
  final int timesUsed;

  SavedCustomer used(DateTime at, {Address? address, String? notes}) => SavedCustomer(
        id: id,
        merchantId: merchantId,
        customer: customer,
        address: address ?? this.address,
        lastUsed: at,
        timesUsed: timesUsed + 1,
        notes: notes ?? this.notes,
      );
}
