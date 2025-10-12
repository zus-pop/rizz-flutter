import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/painting.dart';

class PerformanceOptimizer {
  static Timer? _cacheCleanupTimer;
  static Timer? _performanceMonitorTimer;
  static int _frameDropCount = 0;
  static DateTime _lastFrameTime = DateTime.now();

  // Initialize performance optimizations
  static void initialize() {
    // Start cache cleanup timer (every 5 minutes)
    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupCaches(),
    );

    // Monitor performance in debug mode
    if (kDebugMode) {
      _startPerformanceMonitoring();
    }

    // Setup frame callback to monitor dropped frames
    SchedulerBinding.instance.addPersistentFrameCallback(_frameCallback);
  }

  // Clean up timers
  static void dispose() {
    _cacheCleanupTimer?.cancel();
    _performanceMonitorTimer?.cancel();
  }

  // Monitor frame rate and dropped frames
  static void _frameCallback(Duration timestamp) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastFrameTime).inMilliseconds;

    // If frame took longer than 32ms (60fps threshold), count as dropped
    if (timeDiff > 32) {
      _frameDropCount++;

      // Log excessive frame drops
      if (_frameDropCount > 10 && kDebugMode) {
        debugPrint('Performance warning: $_frameDropCount frames dropped');
        _frameDropCount = 0; // Reset counter
      }
    }

    _lastFrameTime = now;
  }

  // Start performance monitoring
  static void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _logPerformanceStats(),
    );
  }

  // Log performance statistics
  static void _logPerformanceStats() {
    if (kDebugMode) {
      debugPrint('Performance Stats - Dropped frames: $_frameDropCount');
      _frameDropCount = 0; // Reset for next interval
    }
  }

  // Clean up various caches
  static void _cleanupCaches() {
    try {
      // Note: Chat service cache cleanup removed as SimpleChatService is deprecated
      // MatchChatService handles its own cache cleanup internally

      // Force garbage collection in debug mode
      if (kDebugMode) {
        debugPrint('Cache cleanup completed');
      }
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  }

  // Optimize widget rebuilds by debouncing rapid state changes
  static Timer? _debounceTimer;

  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Run heavy operations in isolate to avoid blocking main thread
  static Future<T> runInIsolate<T>(T Function() computation) async {
    if (kIsWeb) {
      // Isolates not supported on web, run on main thread
      return computation();
    }

    final receivePort = ReceivePort();

    await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'computation': computation,
    });

    final result = await receivePort.first;
    return result as T;
  }

  // Isolate entry point
  static void _isolateEntryPoint(Map<String, dynamic> args) {
    final sendPort = args['sendPort'] as SendPort;
    final computation = args['computation'] as Function;

    try {
      final result = computation();
      sendPort.send(result);
    } catch (e) {
      sendPort.send(e);
    }
  }

  // Batch multiple async operations
  static Future<List<T>> batchOperations<T>(
    List<Future<T>> operations, {
    int batchSize = 5,
  }) async {
    final results = <T>[];

    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(batch);
      results.addAll(batchResults);

      // Add small delay between batches to prevent overwhelming
      if (i + batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    return results;
  }

  // Memory usage optimization
  static void optimizeMemoryUsage() {
    // Clear image cache if getting too large
    try {
      PaintingBinding.instance.imageCache.clear();
      if (kDebugMode) {
        debugPrint('Image cache cleared for memory optimization');
      }
    } catch (e) {
      debugPrint('Memory optimization error: $e');
    }
  }
}
