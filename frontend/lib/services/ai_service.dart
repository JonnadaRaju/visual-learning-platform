import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

class AIService {
  AIService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            headers: {'X-Session-ID': AppConfig.instance.sessionId},
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  final Dio _dio;

  Future<String> askQuestion(String question, {String context = ''}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/ask',
      data: {'question': question, 'context': context},
    );
    return response.data?['answer'] as String? ?? 'No answer received';
  }
}

final aiServiceProvider = Provider<AIService>((ref) => AIService());
