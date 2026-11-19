import 'dart:math' as math;

import 'package:corre_core/corre_core.dart';
import 'package:test/test.dart';

void main() {
  group('MinHeap', () {
    test('sai sempre o menor, mesmo com repetidos', () {
      final h = MinHeap<int>((x) => x.toDouble());
      final r = math.Random(1);
      final xs = List.generate(500, (_) => r.nextInt(100));
      xs.forEach(h.push);
      final out = [for (var i = 0; i < xs.length; i++) h.pop()];
      expect(out, [...xs]..sort());
      expect(h.isEmpty, isTrue);
    });

    test('tirar de heap vazio é erro', () {
      expect(() => MinHeap<int>((x) => x.toDouble()).pop(), throwsStateError);
    });
  });

  group('A* na malha de Palmas', () {
    final g = PalmasRoads.graph;
    final r = math.Random(3);

    test('dá o mesmo tempo que o Dijkstra (caminho ótimo) e abre menos nós', () {
      var fewer = 0;
      for (var i = 0; i < 25; i++) {
        final a = r.nextInt(g.nodes.length), b = r.nextInt(g.nodes.length);
        final astar = g.shortestPath(a, b)!, dij = g.dijkstra(a, b)!;
        expect(astar.minutes, closeTo(dij.minutes, 1e-6));
        if (astar.expanded <= dij.expanded) fewer++;
      }
      expect(fewer, 25, reason: 'a heurística nunca deve piorar a busca');
    });

    test('rota começa e termina nos pontos pedidos e cada passo é vizinho', () {
      const a = GeoPoint(-10.1918, -48.3258), b = GeoPoint(-10.2128, -48.3147);
      final route = g.route(a, b);
      expect(route.points.first, a);
      expect(route.points.last, b);
      expect(route.km, greaterThanOrEqualTo(Geo.straightKm(a, b)), reason: 'rua nunca é mais curta que a linha reta');
      expect(route.etaMinutes, greaterThan(0));
    });

    test('mesmo ponto: rota de distância quase zero', () {
      const a = GeoPoint(-10.19, -48.33);
      expect(g.route(a, a).km, lessThan(.5));
    });

    test('prefere avenida quando compensa: tempo menor que andar só em rua local', () {
      const a = GeoPoint(-10.16, -48.335), b = GeoPoint(-10.28, -48.335);
      final route = g.route(a, b);
      final localOnly = Geo.straightKm(a, b) / 22 * 60;
      expect(route.minutes, lessThan(localOnly));
    });
  });
}
