import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'activity_rings.dart';

class AppleStandbyModal extends StatefulWidget {
  final String userName;
  final double habitsPct;
  final double focusPct;

  const AppleStandbyModal({
    super.key,
    required this.userName,
    required this.habitsPct,
    required this.focusPct,
  });

  @override
  State<AppleStandbyModal> createState() => _AppleStandbyModalState();
}

class _AppleStandbyModalState extends State<AppleStandbyModal> {
  late Timer _clockTimer;
  late DateTime _now;
  int _sessionSeconds = 25 * 60;
  bool _isSessionRunning = false;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _toggleSession() {
    HapticFeedback.mediumImpact();
    if (_isSessionRunning) {
      _sessionTimer?.cancel();
      setState(() => _isSessionRunning = false);
    } else {
      setState(() => _isSessionRunning = true);
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_sessionSeconds > 0) {
          if (mounted) setState(() => _sessionSeconds--);
        } else {
          t.cancel();
          if (mounted) {
            setState(() {
              _isSessionRunning = false;
              _sessionSeconds = 25 * 60;
            });
          }
        }
      });
    }
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    final secStr = _now.second.toString().padLeft(2, '0');

    final sessM = (_sessionSeconds ~/ 60).toString().padLeft(2, '0');
    final sessS = (_sessionSeconds % 60).toString().padLeft(2, '0');

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF040508),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xE6040508),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0x33A855F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFC084FC), size: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              ' Standby Focus',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC084FC)),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey)),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Giant Apple Standby Clock
                Text(
                  '$hourStr:$minStr',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: Color(0xFFF59E0B),
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(color: Color(0x80F59E0B), blurRadius: 28),
                    ],
                  ),
                ),
                Text(
                  '${_formatDate(_now)} • ${secStr}s',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Concentric Activity Rings & Timer remaining
                ActivityRingsWidget(
                  overallPct: widget.habitsPct,
                  craftPct: widget.focusPct,
                  vitalityPct: 0.75,
                  size: 160,
                ),

                const SizedBox(height: 24),

                // Session digits
                Text(
                  '$sessM:$sessS',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: CupertinoColors.white,
                  ),
                ),
                const Text(
                  'Zen Focus Session',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),

                const SizedBox(height: 16),

                // Action Start / Pause
                CupertinoButton(
                  color: _isSessionRunning ? CupertinoColors.systemYellow : CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  onPressed: _toggleSession,
                  child: Text(
                    _isSessionRunning ? 'Pause Focus' : 'Start Focus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isSessionRunning ? CupertinoColors.black : CupertinoColors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                Text(
                  ' ${widget.userName} • Live Ecosystem Sync Active',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
