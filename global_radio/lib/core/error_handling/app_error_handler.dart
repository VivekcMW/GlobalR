/// Error handling initialization and global error boundary.
///
/// Wraps the app in error handling zones, catches Flutter framework errors,
/// and reports them to the configured crash service.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'crash_service.dart';

/// Global error handler that wraps the app and catches all uncaught exceptions.
class AppErrorHandler {
  final CrashService _crashService;

  AppErrorHandler(this._crashService);

  /// Initialize error handling and run the app.
  Future<void> runApp(Widget app) async {
    // Set up Flutter framework error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _crashService.recordError(
        details.exception,
        details.stack,
        reason: details.context?.toDescription(),
        fatal: true,
      );
    };

    // Handle errors from the Flutter framework that occur during build
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashService.recordError(error, stack, fatal: true);
      return true;
    };

    // Handle errors from other isolates
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await _crashService.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        reason: 'Isolate error',
        fatal: true,
      );
    }).sendPort);

    // Run the app in a zone that catches all uncaught async errors
    runZonedGuarded(
      () => runAppWidget(app),
      (error, stack) {
        _crashService.recordError(
          error,
          stack,
          reason: 'Uncaught async error',
          fatal: false,
        );
      },
    );
  }

  void runAppWidget(Widget app) {
    // ignore: avoid_manual_providers_as_generated_provider_dependency
    WidgetsFlutterBinding.ensureInitialized();
    runApp(app);
  }
}

/// A widget that catches errors in its subtree and displays a fallback UI.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _DefaultErrorWidget(error: _error!);
    }

    return widget.child;
  }
}

/// Default error widget shown when an error occurs.
class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again or restart the app',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer.withValues(alpha: 0.7),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    error.exception.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom error widget for the entire app (replaces red error screen).
class GlobalErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const GlobalErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app',
                  style: TextStyle(color: Colors.grey),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      '${details.exception}\n${details.stack}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize error widget customization.
void setupErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorWidget(details: details);
  };
}
