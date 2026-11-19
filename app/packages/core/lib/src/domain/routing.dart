import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'geo.dart';

/// Fila de prioridade (heap binário de mínimo). Base do A*: tira sempre o nó mais promissor em O(log n).
class MinHeap<T> {
  MinHeap(this._priorityOf);
  final double Function(T) _priorityOf;
  final _items = <T>[];

  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_priorityOf(_items[parent]) <= _priorityOf(_items[i])) break;
      _swap(i, parent);
      i = parent;
    }
  }

  T pop() {
    if (_items.isEmpty) throw StateError('Heap vazio');
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var smallest = i;
        if (l < _items.length && _priorityOf(_items[l]) < _priorityOf(_items[smallest])) smallest = l;
        if (r < _items.length && _priorityOf(_items[r]) < _priorityOf(_items[smallest])) smallest = r;
        if (smallest == i) break;
        _swap(i, smallest);
        i = smallest;
      }
    }
    return top;
  }

  void _swap(int a, int b) {
    final t = _items[a];
    _items[a] = _items[b];
    _items[b] = t;
  }
}

/// Trecho de rua entre dois cruzamentos.
@immutable
class RoadEdge {
  const RoadEdge(this.to, this.km, this.kmh);
  final int to;
  final double km;

  /// Velocidade média do trecho (avenida é mais rápida que rua local).
  final double kmh;

  double get minutes => km / kmh * 60;
}

/// Resultado de uma rota.
@immutable
class RouteResult {
  const RouteResult({required this.points, required this.km, required this.minutes, required this.expanded});
  final List<GeoPoint> points;
  final double km;
  final double minutes;

  /// Quantos nós o A* precisou abrir (mostra a eficiência da heurística).
  final int expanded;

  int get etaMinutes => math.max(1, minutes.round());
}

/// Grafo de ruas: cruzamentos são nós, trechos são arestas com peso em tempo.
class RoadGraph {
  RoadGraph(this.nodes, this.edges) : assert(nodes.length == edges.length);
  final List<GeoPoint> nodes;
  final List<List<RoadEdge>> edges;

  /// Velocidade máxima do grafo, usada para a heurística do A* nunca superestimar o tempo.
  late final double maxKmh = edges.expand((e) => e).fold<double>(1, (m, e) => math.max(m, e.kmh));

  /// Nó mais próximo de um ponto (busca linear; o grafo da demonstração tem poucos milhares de nós).
  int nearest(GeoPoint p) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < nodes.length; i++) {
      final dLat = nodes[i].lat - p.lat, dLng = nodes[i].lng - p.lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// A*: menor tempo de viagem. A heurística é a linha reta na velocidade máxima,
  /// que nunca passa do tempo real (admissível), então o caminho encontrado é ótimo.
  RouteResult? shortestPath(int from, int to) => _search(from, to, useHeuristic: true);

  /// Dijkstra (A* sem heurística). Mantido para comparar e testar.
  RouteResult? dijkstra(int from, int to) => _search(from, to, useHeuristic: false);

  RouteResult? _search(int from, int to, {required bool useHeuristic}) {
    double h(int n) => useHeuristic ? Geo.straightKm(nodes[n], nodes[to]) / maxKmh * 60 : 0;
    final g = List<double>.filled(nodes.length, double.infinity);
    final came = List<int>.filled(nodes.length, -1);
    final closed = List<bool>.filled(nodes.length, false);
    final open = MinHeap<(int, double)>((e) => e.$2);
    g[from] = 0;
    open.push((from, h(from)));
    var expanded = 0;

    while (!open.isEmpty) {
      final (n, _) = open.pop();
      if (closed[n]) continue;
      closed[n] = true;
      expanded++;
      if (n == to) break;
      for (final e in edges[n]) {
        final cost = g[n] + e.minutes;
        if (cost < g[e.to]) {
          g[e.to] = cost;
          came[e.to] = n;
          open.push((e.to, cost + h(e.to)));
        }
      }
    }
    if (g[to] == double.infinity) return null;

    final path = <int>[];
    for (var n = to; n != -1; n = came[n]) {
      path.add(n);
    }
    final ordered = path.reversed.toList();
    var km = 0.0;
    for (var i = 0; i < ordered.length - 1; i++) {
      km += edges[ordered[i]].firstWhere((e) => e.to == ordered[i + 1]).km;
    }
    return RouteResult(points: [for (final n in ordered) nodes[n]], km: km, minutes: g[to], expanded: expanded);
  }

  /// Rota entre dois pontos quaisquer: liga cada ponta ao cruzamento mais próximo.
  RouteResult route(GeoPoint a, GeoPoint b, {double localKmh = 20}) {
    final ia = nearest(a), ib = nearest(b);
    final core = shortestPath(ia, ib);
    final startKm = Geo.roadKm(a, nodes[ia]), endKm = Geo.roadKm(nodes[ib], b);
    if (core == null) {
      final km = Geo.roadKm(a, b);
      return RouteResult(points: Geo.manhattanPath(a, b), km: km, minutes: km / localKmh * 60, expanded: 0);
    }
    return RouteResult(
      points: [a, ...core.points, b],
      km: startKm + core.km + endKm,
      minutes: core.minutes + (startKm + endKm) / localKmh * 60,
      expanded: core.expanded,
    );
  }
}

/// Malha simplificada das ruas de Palmas: grade de quadras com as avenidas principais mais rápidas
/// (Teotônio Segurado e JK no sentido norte-sul; LO e avenidas a cada quadra no leste-oeste).
abstract final class PalmasRoads {
  static const _minLat = -10.300, _maxLat = -10.140;
  static const _minLng = -48.370, _maxLng = -48.300;
  static const _step = .0025; // ~280 m entre cruzamentos

  static RoadGraph? _cache;
  static RoadGraph get graph => _cache ??= build();

  static RoadGraph build() {
    final rows = ((_maxLat - _minLat) / _step).round() + 1;
    final cols = ((_maxLng - _minLng) / _step).round() + 1;
    final nodes = <GeoPoint>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        nodes.add(GeoPoint(_minLat + r * _step, _minLng + c * _step));
      }
    }
    final edges = List.generate(nodes.length, (_) => <RoadEdge>[]);
    int id(int r, int c) => r * cols + c;

    // Avenidas: colunas e linhas específicas andam mais rápido.
    final teotonio = ((-48.3352 - _minLng) / _step).round();
    final jk = ((-48.3290 - _minLng) / _step).round();
    bool fastCol(int c) => c == teotonio || c == jk || c % 6 == 0;
    bool fastRow(int r) => r % 4 == 0;
    double speedCol(int c) => c == teotonio ? 55 : (fastCol(c) ? 40 : 22);
    double speedRow(int r) => fastRow(r) ? 40 : 22;

    void link(int a, int b, double kmh) {
      final km = Geo.roadKm(nodes[a], nodes[b]) / Geo.roadFactor; // trecho reto: sem fator de curva
      edges[a].add(RoadEdge(b, km, kmh));
      edges[b].add(RoadEdge(a, km, kmh));
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (c + 1 < cols) link(id(r, c), id(r, c + 1), speedRow(r));
        if (r + 1 < rows) link(id(r, c), id(r + 1, c), speedCol(c));
      }
    }
    return RoadGraph(nodes, edges);
  }
}
