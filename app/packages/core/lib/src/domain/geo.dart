import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Ponto geográfico (graus decimais).
@immutable
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat, lng;

  /// Centro de Palmas-TO (Praça dos Girassóis), usado como referência do simulador.
  static const palmas = GeoPoint(-10.1844, -48.3336);

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// Cálculos de distância e rota simples (sem serviço externo).
abstract final class Geo {
  static const _earthRadiusKm = 6371.0;

  /// Fator para estimar a distância de rua a partir da linha reta.
  static const roadFactor = 1.3;

  /// Distância em linha reta (Haversine), em km.
  static double straightKm(GeoPoint a, GeoPoint b) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Distância estimada de rua, em km.
  static double roadKm(GeoPoint a, GeoPoint b) => straightKm(a, b) * roadFactor;

  /// Ponto na fração [t] (0 a 1) do caminho entre [a] e [b].
  static GeoPoint lerp(GeoPoint a, GeoPoint b, double t) {
    final c = t.clamp(0.0, 1.0);
    return GeoPoint(a.lat + (b.lat - a.lat) * c, a.lng + (b.lng - a.lng) * c);
  }

  /// Caminho em "L" (como as avenidas de Palmas): primeiro anda na latitude, depois na longitude.
  static List<GeoPoint> manhattanPath(GeoPoint a, GeoPoint b) => [a, GeoPoint(b.lat, a.lng), b];

  /// Ponto a uma fração [t] de um caminho com vários segmentos.
  static GeoPoint alongPath(List<GeoPoint> path, double t) {
    if (path.length < 2) return path.first;
    final lengths = [for (var i = 0; i < path.length - 1; i++) straightKm(path[i], path[i + 1])];
    final total = lengths.fold<double>(0, (s, l) => s + l);
    if (total == 0) return path.last;
    var target = t.clamp(0.0, 1.0) * total;
    for (var i = 0; i < lengths.length; i++) {
      if (target <= lengths[i] || i == lengths.length - 1) {
        return lerp(path[i], path[i + 1], lengths[i] == 0 ? 1 : target / lengths[i]);
      }
      target -= lengths[i];
    }
    return path.last;
  }

  /// Minutos estimados de moto, a [kmh] km/h.
  static int etaMinutes(double km, {double kmh = 25}) => math.max(1, (km / kmh * 60).round());
}
