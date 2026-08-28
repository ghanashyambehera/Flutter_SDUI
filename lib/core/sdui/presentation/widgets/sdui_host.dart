import 'package:flutter/material.dart';
import 'package:flutter_sdui/core/error/failures.dart';
import 'package:flutter_sdui/core/sdui/domain/entities/sdui_screen.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_action_runner.dart';
import 'package:flutter_sdui/core/sdui/presentation/engine/sdui_controller.dart';
import 'package:flutter_sdui/core/sdui/presentation/renderer/sdui_renderer.dart';

class SduiHost extends StatelessWidget {
  const SduiHost({
    super.key,
    required this.isLoading,
    required this.failure,
    required this.screen,
    required this.controller,
    required this.runner,
    required this.isOffline,
    required this.fromCache,
    required this.onRetry,
  });

  final bool isLoading;
  final Failure? failure;
  final SduiScreen? screen;
  final SduiController? controller;
  final SduiActionRunner? runner;
  final bool isOffline;
  final bool fromCache;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && screen == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (failure != null && screen == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(failure!.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    if (screen == null || controller == null || runner == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final tree = SduiRenderer().build(
      context: context,
      screen: screen!,
      controller: controller!,
      runner: runner!,
    );

    if (!isOffline && !fromCache) return tree;

    return Stack(
      children: [
        tree,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.orange.shade800,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  isOffline
                      ? 'You are offline${fromCache ? ' · showing cached screen' : ''}'
                      : 'Showing cached screen',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
