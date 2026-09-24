import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CatAmbushResult {
  const CatAmbushResult({
    required this.success,
    required this.tapCount,
    required this.rewardExp,
    required this.rewardFurBalls,
    required this.rewardKeycaps,
  });

  final bool success;
  final int tapCount;
  final int rewardExp;
  final int rewardFurBalls;
  final int rewardKeycaps;
}

enum _AmbushPhase { petting, tapping }

class CatAmbushDialog extends StatefulWidget {
  const CatAmbushDialog({super.key});

  @override
  State<CatAmbushDialog> createState() => _CatAmbushDialogState();
}

class _CatAmbushDialogState extends State<CatAmbushDialog> {
  _AmbushPhase _phase = _AmbushPhase.petting;

  double _pettingProgress = 0;
  int _tapCount = 0;
  int _remainingMs = 5000;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🐈 길고양이 기습 출현!'),
      content: SizedBox(
        width: 320,
        child: _phase == _AmbushPhase.petting
            ? _buildPettingPhase(context)
            : _buildTappingPhase(context),
      ),
    );
  }

  Widget _buildPettingPhase(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1단계: 슬라이드 쓰다듬기로 친밀도 100% 채우기'),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: _pettingProgress),
        const SizedBox(height: 12),
        GestureDetector(
          onPanUpdate: _onPettingDrag,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.orange.withValues(alpha: 0.12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                '쓰다듬기 ${(_pettingProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTappingPhase(BuildContext context) {
    final seconds = (_remainingMs / 1000).toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2단계: 5초 안에 궁디팡팡 연타!'),
        const SizedBox(height: 8),
        Text('남은 시간: $seconds초'),
        Text('현재 연타수: $_tapCount'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _onTap,
            child: const Text('궁디팡팡!'),
          ),
        ),
      ],
    );
  }

  void _onPettingDrag(DragUpdateDetails details) {
    final progressUp = (details.delta.distance / 350).clamp(0, 0.08);

    setState(() {
      _pettingProgress = (_pettingProgress + progressUp).clamp(0, 1);
    });

    if ((_pettingProgress * 100).toInt() % 20 == 0) {
      HapticFeedback.selectionClick();
    }

    if (_pettingProgress >= 1) {
      _startTappingPhase();
    }
  }

  void _startTappingPhase() {
    _timer?.cancel();

    setState(() {
      _phase = _AmbushPhase.tapping;
      _tapCount = 0;
      _remainingMs = 5000;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingMs <= 100) {
        timer.cancel();
        _finish();
        return;
      }

      setState(() {
        _remainingMs -= 100;
      });
    });
  }

  void _onTap() {
    if (_phase != _AmbushPhase.tapping) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _tapCount += 1;
    });
  }

  void _finish() {
    final success = _tapCount >= 18;
    final fur = success ? (_tapCount ~/ 4).clamp(3, 40) : 0;
    final keycaps = success ? (_tapCount >= 35 ? 2 : 1) : 0;
    final exp = success ? (10 + _tapCount ~/ 3).clamp(10, 35) : 2;

    Navigator.of(context).pop(
      CatAmbushResult(
        success: success,
        tapCount: _tapCount,
        rewardExp: exp,
        rewardFurBalls: fur,
        rewardKeycaps: keycaps,
      ),
    );
  }
}
