import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/llm_service.dart';
import '../../theme/app_theme.dart';

class GlobalAiStatusIndicator extends StatefulWidget {
  const GlobalAiStatusIndicator({super.key});

  @override
  State<GlobalAiStatusIndicator> createState() => _GlobalAiStatusIndicatorState();
}

class _GlobalAiStatusIndicatorState extends State<GlobalAiStatusIndicator> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    LlmService.instance.modelStatus.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    LlmService.instance.modelStatus.removeListener(_onStatusChanged);
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onStatusChanged() {
    final status = LlmService.instance.modelStatus.value;
    if (status == null) return;

    final s = status.toLowerCase();
    final isTransient = s.contains('complete') || s.contains('ready') || s.contains('sleeping');
    
    if (isTransient) {
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && LlmService.instance.modelStatus.value == status) {
          LlmService.instance.modelStatus.value = null;
        }
      });
    } else {
      _dismissTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: LlmService.instance.modelStatus,
      builder: (context, status, child) {
        if (status == null || status.isEmpty) {
          return const SizedBox.shrink();
        }

        final s = status.toLowerCase();
        final isComplete = s.contains('complete');
        final isReady = s.contains('ready');
        final isSleeping = s.contains('sleeping');
        final isCheckState = isComplete || isReady;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isCheckState
                      ? BopTheme.green.withOpacity(0.2)
                      : isSleeping
                          ? BopTheme.textSecondary.withOpacity(0.1)
                          : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCheckState
                        ? BopTheme.green
                        : isSleeping
                            ? BopTheme.textSecondary.withOpacity(0.5)
                            : BopTheme.textSecondary.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCheckState)
                      const Icon(Icons.check_circle, color: BopTheme.green, size: 16)
                    else if (isSleeping)
                      const Icon(Icons.bedtime, color: BopTheme.textSecondary, size: 16)
                    else
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BopTheme.green,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: isCheckState ? BopTheme.green : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
