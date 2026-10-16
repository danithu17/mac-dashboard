import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'models/habit.dart';
import 'services/sync_service.dart';
import 'widgets/activity_rings.dart';
import 'widgets/awards_dialog.dart';
import 'widgets/sync_settings_dialog.dart';

void main() {
  runApp(const PulseHabitApp());
}

class PulseHabitApp extends StatelessWidget {
  const PulseHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'PulseHabit Pro',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: Color(0xFF0B0F19),
        barBackgroundColor: Color(0xE6101420),
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int xp = 30;
  int level = 1;
  String currentRank = 'Initiate';
  bool isSynced = false;
  String currentFilter = 'All';

  // Notes & Mood
  String selectedMood = '⚡';
  final TextEditingController _noteController = TextEditingController();

  // Focus Timer
  int _timerSeconds = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;

  final List<Habit> habits = [
    Habit(id: '1', name: 'Software Architecture', category: 'Coding', target: 7, icon: '💻', color: '#3b82f6'),
    Habit(id: '2', name: 'Deep Reading & Notes', category: 'Reading', target: 5, icon: '📚', color: '#10b981'),
    Habit(id: '3', name: 'Strength Workout', category: 'Fitness', target: 5, icon: '🏋️', color: '#f43f5e'),
    Habit(id: '4', name: 'Mindfulness & Breathing', category: 'Mindfulness', target: 7, icon: '🧘', color: '#a855f7'),
    Habit(id: '5', name: 'Optimal Hydration', category: 'Hydration', target: 7, icon: '💧', color: '#06b6d4'),
  ];

  final Map<String, bool> _todayLogs = {};

  @override
  void initState() {
    super.initState();
    _noteController.text = 'Focused session completed. Ready for high impact tasks.';
    _trySync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _trySync() async {
    final data = await SyncService.fetchUserData('usr_default');
    if (data != null && mounted) {
      setState(() {
        isSynced = true;
        if (data['boost'] != null && data['boost']['bonusXp'] != null) {
          xp = (data['boost']['bonusXp'] as num).toInt();
          level = (xp ~/ 100) + 1;
        }
      });
    }
  }

  void _toggleCheckIn(String id) {
    setState(() {
      final current = _todayLogs[id] ?? false;
      _todayLogs[id] = !current;
      if (!current) {
        xp += 15;
        if (xp >= 100) {
          level += xp ~/ 100;
          xp = xp % 100;
        }
        if (level >= 5) currentRank = 'Apex Vanguard';
        else if (level >= 3) currentRank = 'Architect';
        else if (level >= 2) currentRank = 'Builder';
      }
    });
    // Trigger background sync push
    SyncService.pushUserData('usr_default', {
      'boost': {'bonusXp': xp},
      'logs': {_todayKey(): _todayLogs},
    }, {
      'name': 'Danithu',
      'avatar': '👨‍💻',
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSeconds > 0) {
          setState(() => _timerSeconds--);
        } else {
          timer.cancel();
          setState(() {
            _isTimerRunning = false;
            xp += 25;
            _timerSeconds = 25 * 60;
          });
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('🎉 Focus Completed!'),
              content: const Text('+25 Profile Boost XP Earned.'),
              actions: [
                CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          );
        }
      });
    }
  }

  void _openAwards() {
    final checkedCount = _todayLogs.values.where((v) => v).length;
    final awards = [
      AwardItem(title: 'First Step', desc: 'Checked in first habit', icon: '🥇', isUnlocked: checkedCount >= 1),
      AwardItem(title: '7-Day Streak', desc: '7 days of consistency', icon: '🔥', isUnlocked: true),
      AwardItem(title: 'Deep Work', desc: 'Completed 50+ Focus XP', icon: '⚡', isUnlocked: xp >= 50),
      AwardItem(title: 'Perfect Day', desc: '100% daily check-in', icon: '🎯', isUnlocked: checkedCount == habits.length),
      AwardItem(title: 'Century Club', desc: '100 check-ins logged', icon: '💎', isUnlocked: false),
      AwardItem(title: 'Zen Master', desc: 'Fitness & mindfulness habits', icon: '🧘', isUnlocked: true),
      AwardItem(title: 'Apex Vanguard', desc: 'Reached Level 5', icon: '🚀', isUnlocked: level >= 5),
      AwardItem(title: 'Consistency King', desc: '20+ active days logged', icon: '🌟', isUnlocked: true),
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => AwardsDialog(awards: awards),
    );
  }

  void _openSyncSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => SyncSettingsDialog(
        onSyncTriggered: () {
          setState(() => isSynced = true);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = currentFilter == 'All'
        ? habits
        : habits.where((h) => h.category == currentFilter).toList();

    final checkedCount = _todayLogs.values.where((v) => v).length;
    final totalCount = habits.length;
    final overallPct = totalCount > 0 ? (checkedCount / totalCount) : 0.0;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/icon.png', width: 22, height: 22, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('🍎')),
            ),
            const SizedBox(width: 8),
            const Text(
              'PulseHabit Pro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openAwards,
              child: const Text('🏅', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _openSyncSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSynced ? const Color(0x3310B981) : const Color(0x33F59E0B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B), width: 0.8),
                ),
                child: Text(
                  isSynced ? '● Synced' : '○ Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 1. PROFILE BOOST BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x2E3B82F6)),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x293B82F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x403B82F6)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('👨‍💻', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Danithu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x333B82F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(currentRank, style: const TextStyle(fontSize: 9, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const Text('Software Engineering • Apple Suite', style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level $level', style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                      Text('$xp / 100 XP', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      color: const Color(0xFF1E2336),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (xp / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF10B981)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. ACTIVITY RINGS CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Row(
                children: [
                  ActivityRingsWidget(
                    overallPct: overallPct,
                    craftPct: 0.65,
                    vitalityPct: 0.40,
                    size: 110,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Activity Rings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                        const Text('Weekly completion goals', style: TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                        const SizedBox(height: 8),
                        _RingLegend(color: const Color(0xFFFA114F), label: 'Overall Goal: ${(overallPct * 100).round()}%'),
                        const SizedBox(height: 4),
                        const _RingLegend(color: Color(0xFFA4FF00), label: 'Craft & Intellect: 65%'),
                        const SizedBox(height: 4),
                        const _RingLegend(color: Color(0xFF00F5EA), label: 'Vitality & Mind: 40%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. CATEGORY PILLS (Horizontal Scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Coding', 'Reading', 'Fitness', 'Mindfulness', 'Hydration'].map((cat) {
                  final isSelected = currentFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: isSelected ? CupertinoColors.systemBlue : const Color(0xFF181D2D),
                      borderRadius: BorderRadius.circular(14),
                      minSize: 28,
                      onPressed: () => setState(() => currentFilter = cat),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // 4. HABITS CHECKLIST
            const Text(
              'DAILY HABITS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),

            ...filteredHabits.map((h) {
              final isDone = _todayLogs[h.id] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDone ? const Color(0x3310B981) : const Color(0x14FFFFFF)),
                ),
                child: Row(
                  children: [
                    Text(h.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text('${h.category} • Target ${h.target} days/wk', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggleCheckIn(h.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF10B981) : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDone ? const Color(0xFF10B981) : const Color(0x33FFFFFF)),
                        ),
                        child: Icon(
                          CupertinoIcons.check_mark,
                          size: 16,
                          color: isDone ? CupertinoColors.black : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 14),

            // 5. FOCUS POMODORO TIMER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Focus Timer (+25 XP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.white)),
                      Text(
                        '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF60A5FA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: _isTimerRunning ? CupertinoColors.systemYellow : CupertinoColors.systemBlue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _toggleTimer,
                          child: Text(_isTimerRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        color: const Color(0xFF1E2336),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          _timer?.cancel();
                          setState(() {
                            _isTimerRunning = false;
                            _timerSeconds = 25 * 60;
                          });
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 12, color: CupertinoColors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 6. DAILY REFLECTION NOTES (Apple Notes Style)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quick Notes & Mood', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.white)),
                      Text(_todayKey(), style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['⚡', '🔥', '😌', '😐', '🔋'].map((mood) {
                      final isSelected = selectedMood == mood;
                      return GestureDetector(
                        onTap: () => setState(() => selectedMood = mood),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x333B82F6) : const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent),
                          ),
                          child: Text(mood, style: const TextStyle(fontSize: 16)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _noteController,
                    maxLines: 3,
                    placeholder: 'Type quick reflection...',
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _RingLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: CupertinoColors.white)),
      ],
    );
  }
}
