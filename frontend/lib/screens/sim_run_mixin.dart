import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Mixin for all simulation screens that compute locally.
/// Call [saveRun] after local computation to persist to Redis + PostgreSQL.
mixin SimRunMixin on ConsumerStatefulWidget {
  // nothing needed here — mixin gives access to ref in state
}

extension SaveRunExtension on ConsumerState {
  /// Saves a locally-computed simulation run to the backend (fire-and-forget).
  /// Never throws — local simulation works even if backend is down.
  void saveRun({
    required String slug,
    required Map<String, dynamic> inputParams,
    required Map<String, dynamic> resultPayload,
  }) {
    ref.read(apiServiceProvider).saveGenericRun(
          slug: slug,
          inputParams: inputParams,
          resultPayload: resultPayload,
        );
  }
}