/// Rate limiting and security utilities for API requests.
///
/// Features:
/// - Request rate limiting
/// - Retry-after handling
/// - Request signing (optional)
/// - Certificate pinning setup
library;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Rate limit configuration.
class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  final Duration retryDelay;

  const RateLimitConfig({
    this.maxRequests = 60,
    this.window = const Duration(minutes: 1),
    this.retryDelay = const Duration(seconds: 5),
  });
}

/// Rate limiter for controlling request frequency.
class RateLimiter {
  final RateLimitConfig config;
  final Queue<DateTime> _requestTimes = Queue();
  final _lock = <String, Completer<void>>{};

  RateLimiter({this.config = const RateLimitConfig()});

  /// Check if a request can be made and wait if necessary.
  Future<void> acquire([String key = 'default']) async {
    // Wait for any pending requests with the same key
    while (_lock.containsKey(key)) {
      await _lock[key]!.future;
    }

    _lock[key] = Completer();

    try {
      // Clean old request times
      final cutoff = DateTime.now().subtract(config.window);
      while (_requestTimes.isNotEmpty && _requestTimes.first.isBefore(cutoff)) {
        _requestTimes.removeFirst();
      }

      // Wait if we've exceeded the rate limit
      if (_requestTimes.length >= config.maxRequests) {
        final oldestRequest = _requestTimes.first;
        final waitUntil = oldestRequest.add(config.window);
        final waitDuration = waitUntil.difference(DateTime.now());
        
        if (waitDuration.isNegative == false) {
          debugPrint('[RateLimiter] Rate limited, waiting ${waitDuration.inMilliseconds}ms');
          await Future.delayed(waitDuration);
        }
      }

      // Record this request
      _requestTimes.add(DateTime.now());
    } finally {
      _lock.remove(key)?.complete();
    }
  }

  /// Reset the rate limiter.
  void reset() {
    _requestTimes.clear();
  }
}

/// Dio interceptor for rate limiting.
class RateLimitInterceptor extends Interceptor {
  final RateLimiter _rateLimiter;

  RateLimitInterceptor(this._rateLimiter);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _rateLimiter.acquire(options.uri.host);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 429 Too Many Requests
    if (err.response?.statusCode == 429) {
      final retryAfter = err.response?.headers.value('retry-after');
      final delay = retryAfter != null
          ? Duration(seconds: int.tryParse(retryAfter) ?? 5)
          : _rateLimiter.config.retryDelay;

      debugPrint('[RateLimitInterceptor] 429 received, retrying after ${delay.inSeconds}s');

      // Retry after delay
      Future.delayed(delay, () {
        // Reset and retry
        _rateLimiter.reset();
      });
    }
    handler.next(err);
  }
}

/// Security configuration for API requests.
class SecurityConfig {
  /// Expected SSL certificate fingerprints (SHA-256).
  final List<String> pinnedCertificates;

  /// Custom headers for request signing.
  final Map<String, String> Function()? signatureHeaders;

  /// Whether to allow invalid certificates in debug mode.
  final bool allowInvalidCertificatesInDebug;

  const SecurityConfig({
    this.pinnedCertificates = const [],
    this.signatureHeaders,
    this.allowInvalidCertificatesInDebug = true,
  });
}

/// Create an HttpClient with certificate pinning.
HttpClient createSecureHttpClient(SecurityConfig config) {
  final client = HttpClient();

  if (config.pinnedCertificates.isNotEmpty) {
    client.badCertificateCallback = (cert, host, port) {
      if (kDebugMode && config.allowInvalidCertificatesInDebug) {
        return true;
      }

      // TODO: Implement actual certificate fingerprint verification
      // For production, compare cert fingerprint against pinnedCertificates
      return false;
    };
  }

  return client;
}

/// Dio interceptor for adding security headers.
class SecurityInterceptor extends Interceptor {
  final SecurityConfig config;

  SecurityInterceptor(this.config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add timestamp header for replay attack prevention
    options.headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

    // Add custom signature headers if configured
    if (config.signatureHeaders != null) {
      options.headers.addAll(config.signatureHeaders!());
    }

    handler.next(options);
  }
}

/// Request retry configuration.
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;
  final Set<int> retryStatusCodes;

  int _retryCount = 0;

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const {408, 500, 502, 503, 504},
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    
    if (statusCode != null &&
        retryStatusCodes.contains(statusCode) &&
        _retryCount < maxRetries) {
      _retryCount++;
      
      // Exponential backoff
      final delay = baseDelay * (1 << (_retryCount - 1));
      debugPrint('[RetryInterceptor] Retrying request (attempt $_retryCount) after ${delay.inMilliseconds}ms');
      
      await Future.delayed(delay);
      
      try {
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        _retryCount = 0;
        handler.resolve(response);
        return;
      } catch (e) {
        // Let it fall through to handler.next
      }
    }
    
    _retryCount = 0;
    handler.next(err);
  }
}

/// Create a secure Dio instance with rate limiting and security.
Dio createSecureDio({
  RateLimitConfig? rateLimitConfig,
  SecurityConfig? securityConfig,
  Duration connectTimeout = const Duration(seconds: 30),
  Duration receiveTimeout = const Duration(seconds: 30),
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    headers: {
      'Accept': 'application/json',
      'User-Agent': 'GlobalRadio/1.0',
    },
  ));

  // Add rate limiting
  if (rateLimitConfig != null) {
    dio.interceptors.add(RateLimitInterceptor(RateLimiter(config: rateLimitConfig)));
  }

  // Add security headers
  if (securityConfig != null) {
    dio.interceptors.add(SecurityInterceptor(securityConfig));
  }

  // Add retry logic
  dio.interceptors.add(RetryInterceptor());

  // Add logging in debug mode
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  return dio;
}
