import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  bool _initialized = false;

  void initialize({required String baseUrl}) {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
        } catch (_) {
          // Supabase not initialized or no session — proceed without auth
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            await Supabase.instance.client.auth.refreshSession();
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              error.requestOptions.headers['Authorization'] =
                  'Bearer ${session.accessToken}';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          } catch (_) {}
        }
        return handler.next(error);
      },
    ));

    _initialized = true;
  }

  // ─── Safe request helper ─────────────────────────────
  Future<T> _safeRequest<T>(Future<T> Function() request, T fallback) async {
    try {
      return await request();
    } on DioException catch (e) {
      print('[ApiService] DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('[ApiService] Status: ${e.response?.statusCode} Body: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('[ApiService] Error: $e');
      rethrow;
    }
  }

  // ─── Patients ───────────────────────────────────────
  Future<Map<String, dynamic>> getPatient(String id) async {
    return _safeRequest(() async {
      final response = await _dio.get('/patients/$id');
      return response.data['data'] ?? {};
    }, {});
  }

  Future<Map<String, dynamic>> getPatientPrescriptions(String id, {int limit = 20, int offset = 0}) async {
    return _safeRequest(() async {
      final response = await _dio.get('/patients/$id/prescriptions', queryParameters: {'limit': limit, 'offset': offset});
      return response.data ?? {};
    }, {});
  }

  Future<Map<String, dynamic>> getPatientAlerts(String id, {int limit = 20, int offset = 0}) async {
    return _safeRequest(() async {
      final response = await _dio.get('/patients/$id/alerts', queryParameters: {'limit': limit, 'offset': offset});
      return response.data ?? {};
    }, {});
  }

  // ─── Prescriptions ─────────────────────────────────
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> body) async {
    return _safeRequest(() async {
      final response = await _dio.post('/prescriptions', data: body);
      return response.data['data'] ?? {};
    }, {});
  }

  Future<Map<String, dynamic>> getPrescription(String id) async {
    return _safeRequest(() async {
      final response = await _dio.get('/prescriptions/$id');
      return response.data['data'] ?? {};
    }, {});
  }

  Future<Map<String, dynamic>> addDrugToPrescription(String prescriptionId, Map<String, dynamic> body) async {
    return _safeRequest(() async {
      final response = await _dio.post('/prescriptions/$prescriptionId/drugs', data: body);
      return response.data['data'] ?? {};
    }, {});
  }

  Future<void> removeDrugFromPrescription(String prescriptionId, String drugId) async {
    return _safeRequest(() async {
      await _dio.delete('/prescriptions/$prescriptionId/drugs/$drugId');
    }, null);
  }

  Future<Map<String, dynamic>> safetyCheck(String prescriptionId) async {
    return _safeRequest(() async {
      final response = await _dio.get('/prescriptions/$prescriptionId/safety-check');
      return response.data['data'] ?? {};
    }, {});
  }

  // ─── Drugs ──────────────────────────────────────────
  Future<List<dynamic>> searchDrugs(String query) async {
    return _safeRequest(() async {
      final response = await _dio.get('/drugs/search', queryParameters: {'q': query});
      return response.data['data'] ?? [];
    }, []);
  }

  Future<Map<String, dynamic>> getDrug(String id) async {
    return _safeRequest(() async {
      final response = await _dio.get('/drugs/$id');
      return response.data['data'] ?? {};
    }, {});
  }

  Future<List<dynamic>> getDrugIngredients(String drugId) async {
    return _safeRequest(() async {
      final response = await _dio.get('/drugs/$drugId/ingredients');
      return response.data['data'] ?? [];
    }, []);
  }

  Future<Map<String, dynamic>> getDrugsList({int limit = 20, int offset = 0}) async {
    return _safeRequest(() async {
      final response = await _dio.get('/drugs', queryParameters: {'limit': limit, 'offset': offset});
      return response.data ?? {};
    }, {});
  }

  // ─── Alerts ─────────────────────────────────────────
  Future<Map<String, dynamic>> getAlerts({int limit = 20, int offset = 0, String? severity, String? status}) async {
    return _safeRequest(() async {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (severity != null) params['severity'] = severity;
      if (status != null) params['status'] = status;
      final response = await _dio.get('/alerts', queryParameters: params);
      return response.data ?? {};
    }, {});
  }

  Future<Map<String, dynamic>> getAlert(String id) async {
    return _safeRequest(() async {
      final response = await _dio.get('/alerts/$id');
      return response.data['data'] ?? {};
    }, {});
  }

  Future<void> acknowledgeAlert(String id, {String? overrideReason}) async {
    return _safeRequest(() async {
      await _dio.post('/alerts/$id/acknowledge', data: {'overrideReason': overrideReason});
    }, null);
  }

  Future<void> batchAcknowledgeAlerts(List<String> alertIds, {String? overrideReason}) async {
    return _safeRequest(() async {
      await _dio.post('/alerts/batch-acknowledge', data: {
        'alertIds': alertIds,
        'overrideReason': overrideReason,
      });
    }, null);
  }

  // ─── Interactions ───────────────────────────────────
  Future<Map<String, dynamic>> checkInteractions(List<String> drugIds) async {
    return _safeRequest(() async {
      final response = await _dio.post('/interactions/check', data: {'drugIds': drugIds});
      return response.data['data'] ?? {};
    }, {});
  }

  // ─── Analytics ──────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    return _safeRequest(() async {
      final response = await _dio.get('/analytics/dashboard-stats');
      return response.data['data'] ?? {};
    }, {});
  }

  Future<List<dynamic>> getTopInteractions({int days = 30}) async {
    return _safeRequest(() async {
      final response = await _dio.get('/analytics/top-interactions', queryParameters: {'days': days});
      return response.data['data'] ?? [];
    }, []);
  }

  Future<List<dynamic>> getAlertTrends({int days = 30}) async {
    return _safeRequest(() async {
      final response = await _dio.get('/analytics/alert-trends', queryParameters: {'days': days});
      return response.data['data'] ?? [];
    }, []);
  }

  Future<List<dynamic>> getSeverityDistribution() async {
    return _safeRequest(() async {
      final response = await _dio.get('/analytics/severity-distribution');
      return response.data['data'] ?? [];
    }, []);
  }
}
