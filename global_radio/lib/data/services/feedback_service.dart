import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Feedback service for submitting user feedback.
class FeedbackService {
  FeedbackService(this._dio);

  final Dio _dio;

  /// Feedback support email.
  static const String supportEmail = 'support@globalradio.app';

  /// Feedback webhook endpoint (optional - for backend collection).
  static const String? feedbackEndpoint = null; // Set to your endpoint URL

  /// Submit feedback to backend or fallback to email.
  Future<bool> submitFeedback({
    required String message,
    required int rating,
    String? category,
    bool includeDeviceInfo = true,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      // Try backend endpoint first if configured
      if (feedbackEndpoint != null) {
        return await _submitToBackend(
          message: message,
          rating: rating,
          category: category,
          deviceInfo: includeDeviceInfo ? deviceInfo : null,
        );
      }

      // Fallback to email
      return await _submitViaEmail(
        message: message,
        rating: rating,
        category: category,
        deviceInfo: includeDeviceInfo ? deviceInfo : null,
      );
    } catch (e) {
      debugPrint('FeedbackService: Error submitting feedback: $e');
      return false;
    }
  }

  /// Submit to backend API.
  Future<bool> _submitToBackend({
    required String message,
    required int rating,
    String? category,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        feedbackEndpoint!,
        data: {
          'message': message,
          'rating': rating,
          'category': category,
          'deviceInfo': deviceInfo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('FeedbackService: Backend submission failed: $e');
      // Fall back to email
      return _submitViaEmail(
        message: message,
        rating: rating,
        category: category,
        deviceInfo: deviceInfo,
      );
    }
  }

  /// Submit via email client.
  Future<bool> _submitViaEmail({
    required String message,
    required int rating,
    String? category,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final ratingStars = '★' * rating + '☆' * (5 - rating);

      final body = StringBuffer()
        ..writeln('Rating: $ratingStars ($rating/5)')
        ..writeln();

      if (category != null && category.isNotEmpty) {
        body.writeln('Category: $category');
        body.writeln();
      }

      body.writeln('Feedback:');
      body.writeln(message);
      body.writeln();

      if (deviceInfo != null) {
        body.writeln('--- Device Info ---');
        deviceInfo.forEach((key, value) {
          body.writeln('$key: $value');
        });
      }

      body.writeln();
      body.writeln('App Version: ${packageInfo.version}+${packageInfo.buildNumber}');

      final subject = 'Global Radio Feedback - $ratingStars';
      final emailUri = Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body.toString(),
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri);
      }

      return false;
    } catch (e) {
      debugPrint('FeedbackService: Email submission failed: $e');
      return false;
    }
  }

  /// Open email client for direct contact.
  Future<bool> openEmailClient({String? subject, String? body}) async {
    try {
      final emailUri = Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: _encodeQueryParameters({
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        return await launchUrl(emailUri);
      }

      return false;
    } catch (e) {
      debugPrint('FeedbackService: Failed to open email client: $e');
      return false;
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}

/// Feedback service provider.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return FeedbackService(dio);
});
