import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class QuoteTimer extends StatefulWidget {
  final String validUntilIso;
  final VoidCallback onExpired;

  const QuoteTimer({
    super.key,
    required this.validUntilIso,
    required this.onExpired,
  });

  @override
  State<QuoteTimer> createState() => _QuoteTimerState();
}

class _QuoteTimerState extends State<QuoteTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final validUntil = DateTime.parse(widget.validUntilIso);
    final now =
        DateTime.now().toUtc(); // Assuming API sends UTC or correct offset
    _remaining = validUntil.difference(now);

    if (_remaining.isNegative) {
      widget.onExpired();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final now = DateTime.now().toUtc();
        _remaining = validUntil.difference(now);
      });

      if (_remaining.isNegative) {
        timer.cancel();
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) return const SizedBox.shrink();

    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.infoBlue),
          const SizedBox(width: 8),
          Text(
            'Price valid for ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppColors.infoBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
