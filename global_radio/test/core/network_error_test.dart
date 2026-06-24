import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/network/network_error_handler.dart';

void main() {
  group('NetworkError', () {
    group('fromDioException', () {
      test('handles connection timeout', () {
        final error = NetworkError.fromDioException(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(),
          ),
        );

        expect(error.type, equals(NetworkErrorType.timeout));
        expect(error.isRetryable, isTrue);
      });

      test('handles connection error', () {
        final error = NetworkError.fromDioException(
          DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(),
          ),
        );

        expect(error.type, equals(NetworkErrorType.noConnection));
        expect(error.isRetryable, isTrue);
      });

      test('handles 500 server error', () {
        final error = NetworkError.fromDioException(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        expect(error.type, equals(NetworkErrorType.serverError));
        expect(error.statusCode, equals(500));
        expect(error.isRetryable, isTrue);
      });

      test('handles 401 client error as non-retryable', () {
        final error = NetworkError.fromDioException(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        expect(error.type, equals(NetworkErrorType.clientError));
        expect(error.statusCode, equals(401));
        expect(error.isRetryable, isFalse);
      });

      test('handles cancelled request', () {
        final error = NetworkError.fromDioException(
          DioException(
            type: DioExceptionType.cancel,
            requestOptions: RequestOptions(),
          ),
        );

        expect(error.type, equals(NetworkErrorType.cancelled));
        expect(error.isRetryable, isFalse);
      });
    });

    group('fromException', () {
      test('handles SocketException', () {
        final error = NetworkError.fromException(
          const SocketException('No route to host'),
        );

        expect(error.type, equals(NetworkErrorType.noConnection));
      });

      test('handles generic exception', () {
        final error = NetworkError.fromException(Exception('Unknown error'));

        expect(error.type, equals(NetworkErrorType.unknown));
      });
    });
  });

  group('RetryConfig', () {
    test('getDelay returns correct exponential backoff', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
      );

      expect(config.getDelay(1), equals(const Duration(seconds: 2)));
      expect(config.getDelay(2), equals(const Duration(seconds: 4)));
      expect(config.getDelay(3), equals(const Duration(seconds: 6)));
    });

    test('getDelay respects maxDelay', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 10),
        backoffMultiplier: 2.0,
        maxDelay: Duration(seconds: 30),
      );

      expect(config.getDelay(5), equals(const Duration(seconds: 30)));
    });

    test('shouldRetry returns false when max retries exceeded', () {
      const config = RetryConfig(maxRetries: 3);
      final error = NetworkError(
        type: NetworkErrorType.timeout,
        message: 'test',
        userMessage: 'test',
      );

      expect(config.shouldRetry(error, 2), isTrue);
      expect(config.shouldRetry(error, 3), isFalse);
    });

    test('shouldRetry returns false for non-retryable errors', () {
      const config = RetryConfig();
      final error = NetworkError(
        type: NetworkErrorType.clientError,
        message: 'test',
        userMessage: 'test',
        isRetryable: false,
      );

      expect(config.shouldRetry(error, 0), isFalse);
    });
  });
}
