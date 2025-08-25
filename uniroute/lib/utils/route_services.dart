// route_services.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_services.dart';
import 'package:flutter/foundation.dart';

class RouteServices {
  // Update this if your backend host/path differs
  static const String baseUrl = 'http://172.55.4.160:3000/api';

  // in-memory cache keyed by normalized id string
  static final Map<String, List<String>> _timesCache = {};
  static final Map<String, Map<String, dynamic>> _routesCache = {};

  // ----------------- Helpers -----------------

  /// Return a normalized string id for a variety of shapes (int, double, uuid, numeric string).
  static String _normalizeId(dynamic raw) {
    if (raw == null) return '';
    if (raw is int) return raw.toString();
    if (raw is double) return raw.toInt().toString();
    final s = raw.toString();
    try {
      if (s.contains('.')) return double.parse(s).toInt().toString();
      return int.parse(s).toString();
    } catch (_) {
      // fallback: return trimmed string (could be a uuid)
      return s.trim();
    }
  }

  /// Trim/format a time-like string to "HH:mm"
  static String _trimToHourMinute(String s) {
    if (s.isEmpty) return '';
    s = s.trim();

    // If ISO datetime: parse and extract hour/minute
    try {
      if (s.contains('T')) {
        final dt = DateTime.parse(s);
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      }
    } catch (_) {}

    // If contains colons like "07:45:00" or "07:45"
    final parts = s.split(':');
    if (parts.length >= 2) {
      final hh = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      return '$hh:$mm';
    }

    // maybe plain number or text — return as-is
    return s;
  }

  /// Parse many shapes: string, map, nested map -> hour:minute
  static String _parseTime(dynamic item) {
    if (item == null) return '';
    if (item is String) return _trimToHourMinute(item);
    if (item is num) return _trimToHourMinute(item.toString());
    if (item is Map) {
      final possibleKeys = [
        'departure_time',
        'departureTime',
        'time',
        'value',
        'departure'
      ];
      for (final k in possibleKeys) {
        if (item.containsKey(k) && item[k] != null) {
          return _trimToHourMinute(item[k].toString());
        }
      }
      // fallback: use first primitive value found
      for (final v in item.values) {
        if (v is String || v is num) {
          return _trimToHourMinute(v.toString());
        }
      }
    }
    // last resort
    return _trimToHourMinute(item.toString());
  }

  // ----------------- Public API -----------------

  /// Fetch list of routes. Normalizes results to
  /// { 'route_id': '<id-as-string-or-uuid>', 'route_name': '<name>', 'raw': <original map> }
  static Future<List<Map<String, dynamic>>> fetchRoutes(
      {Duration timeout = const Duration(seconds: 10)}) async {
    final headers = await AuthServices.authHeaders();
    final uri = Uri.parse('$baseUrl/routes');

    http.Response resp;
    try {
      resp = await http.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException catch (e) {
      throw Exception('Timeout fetching routes: ${e.message ?? ''}');
    } catch (e) {
      throw Exception('Network error fetching routes: $e');
    }

    if (resp.statusCode != 200) {
      throw Exception('Failed to load routes: ${resp.statusCode} ${resp.body}');
    }

    final dynamic decoded = json.decode(resp.body);
    if (decoded is! List) {
      throw Exception('Unexpected routes response: expected JSON array.');
    }

    final normalized = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is Map) {
        final raw = Map<String, dynamic>.from(item);
        final rawId =
            raw['route_id'] ?? raw['id'] ?? raw['routeId'] ?? raw['RouteId'];
        final rawName = raw['route_name'] ??
            raw['name'] ??
            raw['routeName'] ??
            raw['RouteName'] ??
            '';
        final id = _normalizeId(rawId);
        final name = rawName?.toString() ?? '';
        final map = {'route_id': id, 'route_name': name, 'raw': raw};
        normalized.add(map);
        _routesCache[id] = map;
      }
    }

    return normalized;
  }

  /// Robust fetch of route times.
  /// Tries several likely endpoint shapes if some return 404.
  static Future<List<String>> fetchRouteTimes(dynamic routeId,
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (routeId == null) return [];

    final idStr = _normalizeId(routeId);
    if (idStr.isEmpty) return [];

    // Return cached if present
    if (_timesCache.containsKey(idStr)) {
      return List<String>.from(_timesCache[idStr]!);
    }

    final headers = await AuthServices.authHeaders();

    // Candidate paths to try
    final candidatePaths = <String>[
      '/routes/$idStr/times',
      '/routes/$idStr/route_times',
      '/route_times?route_id=$idStr',
      '/route-times?route_id=$idStr',
      '/route_times/$idStr',
      '/route_times/route/$idStr',
      '/routes/stops?route_id=$idStr',
      '/routes/stops?id=$idStr',
    ];

    Exception? lastException;
    for (final path in candidatePaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        debugPrint('RouteServices: trying $uri');
        final resp = await http.get(uri, headers: headers).timeout(timeout);
        debugPrint('RouteServices: got ${resp.statusCode} from $uri');

        // preview of body for logs (trim long HTML)
        final preview = resp.body.length > 400
            ? '${resp.body.substring(0, 400)}...'
            : resp.body;
        debugPrint('RouteServices: preview: $preview');

        if (resp.statusCode == 200) {
          final dynamic decoded = json.decode(resp.body);
          final parsed = <String>[];

          if (decoded is List) {
            for (final item in decoded) {
              final t = _parseTime(item);
              if (t.isNotEmpty) parsed.add(t);
            }
          } else if (decoded is Map) {
            // common wrappers==================================================
            final candidates = [
              decoded['data'],
              decoded['times'],
              decoded['departure_times'],
              decoded['result'],
              decoded['items']
            ];
            var foundList = false;
            for (final c in candidates) {
              if (c is List) {
                for (final item in c) {
                  final t = _parseTime(item);
                  if (t.isNotEmpty) parsed.add(t);
                }
                foundList = true;
                break;
              }
            }
            if (!foundList) {
              final t = _parseTime(decoded);
              if (t.isNotEmpty) parsed.add(t);
            }
          } else {
            // fallback: split by commas or take trimmed body
            final s = resp.body;
            if (s.contains(',')) {
              parsed.addAll(s.split(',').map((e) => _trimToHourMinute(e)));
            } else {
              final t = _trimToHourMinute(s);
              if (t.isNotEmpty) parsed.add(t);
            }
          }

          // dedupe while preserving order
          final unique = <String>[];
          for (final t in parsed) {
            if (!unique.contains(t)) unique.add(t);
          }

          _timesCache[idStr] = unique;
          return List<String>.from(unique);
        } else if (resp.statusCode == 404) {
          // not the right endpoint — try next candidate
          debugPrint(
              'RouteServices: $uri returned 404, trying next candidate.');
          continue;
        } else {
          // other error (401/403/500/etc) — surface it
          throw Exception(
              'Failed to load route times for $idStr: ${resp.statusCode} $preview');
        }
      } on TimeoutException catch (e) {
        lastException =
            Exception('Timeout when fetching $path: ${e.message ?? ''}');
        debugPrint(lastException.toString());
        continue; // try next path
      } catch (e) {
        lastException =
            Exception('Network or parse error when fetching $path: $e');
        debugPrint(lastException.toString());
        continue;
      }
    }

    if (lastException != null) throw lastException;
    throw Exception(
        'No matching route-times endpoint found for $idStr (checked ${candidatePaths.length} paths).');
  }

  /// clear in-memory caches (useful for debugging)
  static void clearCache() {
    _timesCache.clear();
    _routesCache.clear();
  }
}
