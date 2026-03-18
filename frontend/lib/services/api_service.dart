import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/compute_result.dart';
import '../models/concept.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            headers: {'X-Session-ID': AppConfig.instance.sessionId},
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  final Dio _dio;

  // ── Simulations (topics) ───────────────────────────────────────────────────

  /// Fetches all simulations from the backend.
  /// Each simulation now includes subject_id, emoji, class_range
  /// so the Flutter app doesn't need a hardcoded topic catalog.
  Future<List<SimulationDefinition>> fetchSimulations() async {
    final response =
        await _request(() => _dio.get<Map<String, dynamic>>('/simulations'));
    final list = (response.data?['simulations'] ?? []) as List<dynamic>;
    return list
        .map((e) => SimulationDefinition.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Compute ────────────────────────────────────────────────────────────────

  Future<ProjectileResult> runProjectile(Map<String, double> body) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
          '/simulations/projectile', data: body),
    );
    return ProjectileResult.fromJson(response.data!);
  }

  Future<WaveResult> runWave(Map<String, dynamic> body) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>('/simulations/waves', data: body),
    );
    return WaveResult.fromJson(response.data!);
  }

  Future<WaveSuperpositionResult> runSuperposition(
      List<Map<String, dynamic>> waves) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
          '/simulations/waves/superposition', data: {'waves': waves}),
    );
    return WaveSuperpositionResult.fromJson(response.data!);
  }

  Future<CircuitResult> runCircuit(
      List<Map<String, dynamic>> components) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
          '/simulations/circuits', data: {'components': components}),
    );
    return CircuitResult.fromJson(response.data!);
  }

  // ── Runs / History ─────────────────────────────────────────────────────────

  Future<void> saveRun(String runId) async {
    await _request(
        () => _dio.post('/runs/save', data: {'run_id': runId}));
  }

  Future<List<RunSummary>> fetchRuns() async {
    final response =
        await _request(() => _dio.get<Map<String, dynamic>>('/runs'));
    return ((response.data?['runs'] ?? []) as List)
        .map((e) =>
            RunSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<RunStats> fetchRunStats() async {
    final response =
        await _request(() => _dio.get<Map<String, dynamic>>('/runs/stats'));
    return RunStats.fromJson(response.data!);
  }

  // ── AI Assistant ───────────────────────────────────────────────────────────

  Future<String> explainTopic(String topic) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>('/ai/explain', data: {'topic': topic}),
    );
    return response.data?['answer'] as String? ?? 'No explanation received';
  }

  Future<String> askQuestion(String question, {String context = '', String topic = ''}) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/ai/ask',
        data: {'question': question, 'context': context, 'topic': topic},
      ),
    );
    return response.data?['answer'] as String? ?? 'No answer received';
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<Response<T>> _request<T>(
      Future<Response<T>> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final detail = error.response?.data is Map<String, dynamic>
          ? (error.response?.data as Map<String, dynamic>)['detail']
              ?.toString()
          : null;
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Network error: backend is unreachable at ${AppConfig.apiBaseUrl}');
      }
      if (status == 400) throw Exception(detail ?? 'Invalid request');
      if (status == 404)
        throw Exception(detail ?? 'Requested resource was not found');
      if (status == 422)
        throw Exception(detail ?? 'Input validation failed');
      if (status == 500)
        throw Exception('Server error: please check backend logs');
      throw Exception(detail ?? error.message ?? 'Request failed');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());