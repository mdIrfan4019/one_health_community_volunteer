import 'package:http/http.dart' as http;
import 'package:cohv/core/storage/session_manager.dart';

/// Centralized HTTP client wrapper that automatically intercepts all outgoing
/// HTTP requests and injects the `Authorization: Bearer <token>` header if a
/// valid session exists in [SessionManager] and is not already provided.
///
/// Works with all REST calls (`get`, `post`, `put`, `delete`, `multipart`, etc.).
class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;

  AuthenticatedHttpClient([http.Client? inner])
      : _inner = inner ?? http.Client();

  /// Shared singleton instance for reuse across services
  static final AuthenticatedHttpClient instance = AuthenticatedHttpClient();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Automatically inject Authorization header if missing
    if (!request.headers.containsKey('Authorization')) {
      final token = SessionManager.cachedToken ?? await SessionManager.getToken();
      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    }

    // 2. Ensure standard Accept header for JSON APIs if missing
    if (!request.headers.containsKey('Accept')) {
      request.headers['Accept'] = 'application/json';
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

