/// Network error handling with retry logic and user-friendly error messages.
///
/// Provides:
/// - Automatic retry with exponential backoff
/// - Offline detection
/// - User-friendly error messages
/// - Error classification (network, server, timeout, etc.)
library;

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error types for classification.
enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  clientError,
  cancelled,
  unknown,
}

/// Structured network error with user-friendly message.
class NetworkError implements Exception {
  final NetworkErrorType type;
  final String message;
  final String userMessage;
  final int? statusCode;
  final dynamic originalError;
  final bool isRetryable;

  const NetworkError({
    required this.type,
    required this.message,
    required this.userMessage,
    this.statusCode,
    this.originalError,
    this.isRetryable = true,
  });

  factory NetworkError.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          type: NetworkErrorType.timeout,
          message: 'Request timed out: ${e.message}',
          userMessage: 'Connection is slow. Please try again.',
          originalError: e,
        );
      case DioExceptionType.connectionError:
        return NetworkError(
          type: NetworkErrorType.noConnection,
          message: 'Connection error: ${e.message}',
          userMessage: 'No internet connection. Please check your network.',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode >= 500) {
          return NetworkError(
            type: NetworkErrorType.serverError,
            message: 'Server error: $statusCode',
            userMessage: 'Our servers are having issues. Please try again later.',
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode >= 400) {
          return NetworkError(
            type: NetworkErrorType.clientError,
            message: 'Client error: $statusCode',
            userMessage: 'Something went wrong. Please try again.',
            statusCode: statusCode,
            originalError: e,
            isRetryable: statusCode != 401 && statusCode != 403 && statusCode != 404,
          );
        }
        return NetworkError(
          type: NetworkErrorType.unknown,
          message: 'Response error: $statusCode',
          userMessage: 'Something went wrong. Please try again.',
          statusCode: statusCode,
          originalError: e,
        );
      case DioExceptionType.cancel:
        return NetworkError(
          type: NetworkErrorType.cancelled,
          message: 'Request cancelled',
          userMessage: 'Request was cancelled.',
          originalError: e,
          isRetryable: false,
        );
      default:
        return NetworkError(
          type: NetworkErrorType.unknown,
          message: 'Unknown error: ${e.message}',
          userMessage: 'Something went wrong. Please try again.',
          originalError: e,
        );
    }
  }

  factory NetworkError.fromException(dynamic e) {
    if (e is DioException) {
      return NetworkError.fromDioException(e);
    }
    if (e is SocketException) {
      return NetworkError(
        type: NetworkErrorType.noConnection,
        message: 'Socket exception: ${e.message}',
        userMessage: 'No internet connection. Please check your network.',
        originalError: e,
      );
    }
    if (e is TimeoutException) {
      return NetworkError(
        type: NetworkErrorType.timeout,
        message: 'Timeout: ${e.message}',
        userMessage: 'Connection is slow. Please try again.',
        originalError: e,
      );
    }
    return NetworkError(
      type: NetworkErrorType.unknown,
      message: 'Error: $e',
      userMessage: 'Something went wrong. Please try again.',
      originalError: e,
    );
  }

  @override
  String toString() => 'NetworkError($type): $message';
}

/// Retry configuration.
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final Set<NetworkErrorType> retryableErrors;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryableErrors = const {
      NetworkErrorType.noConnection,
      NetworkErrorType.timeout,
      NetworkErrorType.serverError,
    },
  });

  Duration getDelay(int attempt) {
    final delay = initialDelay * (backoffMultiplier * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  bool shouldRetry(NetworkError error, int attempt) {
    return attempt < maxRetries &&
        error.isRetryable &&
        retryableErrors.contains(error.type);
  }
}

/// Network error handler with retry logic.
class NetworkErrorHandler {
  final RetryConfig retryConfig;

  const NetworkErrorHandler({
    this.retryConfig = const RetryConfig(),
  });

  /// Execute a network operation with automatic retry.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    void Function(NetworkError, int)? onRetry,
  }) async {
    final retryConf = config ?? retryConfig;
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        final error = NetworkError.fromException(e);
        
        if (retryConf.shouldRetry(error, attempt)) {
          attempt++;
          final delay = retryConf.getDelay(attempt);
          debugPrint('Retry $attempt after ${delay.inSeconds}s: ${error.message}');
          onRetry?.call(error, attempt);
          await Future.delayed(delay);
        } else {
          throw error;
        }
      }
    }
  }
}

/// Connectivity status provider.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Current network status.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) => results.any((r) => r != ConnectivityResult.none),
    orElse: () => true, // Assume online if unknown
  );
});

/// Network error handler provider.
final networkErrorHandlerProvider = Provider<NetworkErrorHandler>((ref) {
  return const NetworkErrorHandler();
});

/// Dio with error interceptor.
Dio createDioWithErrorHandling({
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

  dio.interceptors.add(LogInterceptor(
    requestBody: kDebugMode,
    responseBody: kDebugMode,
    error: true,
  ));

  return dio;
}
