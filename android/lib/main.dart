import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models/habit.dart';
import 'services/sync_service.dart';

void main() {
  runApp(const PulseHabitApp());
}

class PulseHabitApp extends StatelessWidget {
  const PulseHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'PulseHabit Pro',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: Color(0xFF0B0F19),
        barBackgroundColor: Color(0xCC12141C),
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
  int xp = 45;
  int level = 1;
  String currentRank = 'Initiate';
  bool isSynced = false;

  final List<Habit> habits = [
    Habit(id: '1', name: 'Software Architecture', category: 'Coding', target: 7, icon: '💻', color: '#3b82f6'),
    Habit(id: '2', name: 'Deep Focus & Reading', category: 'Reading', target: 5, icon: '📚', color: '#10b981'),
    Habit(id: '3', name: 'Daily Workout', category: 'Fitness', target: 5, icon: '🏋️', color: '#f43f5e'),
  ];

  @override
  void initState() {
    super.initState();
    _trySync();
  }

  Future<void> _trySync() async {
    final data = await SyncService.fetchUserData('usr_default');
    if (data != null && mounted) {
      setState(() {
        isSynced = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.circle_grid_hex, size: 18, color: CupertinoColors.systemBlue),
            SizedBox(width: 6),
            Text('PulseHabit Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSynced ? const Color(0x3310B981) : const Color(0x33F59E0B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isSynced ? '● Synced' : '○ Local',
                style: TextStyle(
                  fontSize: 10,
                  color: isSynced ? CupertinoColors.systemGreen : CupertinoColors.systemYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Boost Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x223B82F6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x333B82F6),
                          borderRadius: BorderRadius.circular(16),
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
                                const Text('Danithu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x333B82F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(currentRank, style: const TextStyle(fontSize: 9, color: Color(0xFF60A5FA))),
                                ),
                              ],
                            ),
                            const Text('Software Engineering', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level $level', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemYellow, fontWeight: FontWeight.bold)),
                      Text('$xp / 100 XP', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xp / 100,
                      backgroundColor: const Color(0xFF23263B),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF3B82F6)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Activity Rings Mock Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.flame_fill, color: Color(0xFFFA114F), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Activity Rings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Synced with Web & Desktop', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('85%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFA114F))),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('DAILY HABITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey, letterSpacing: 0.5)),
            const SizedBox(height: 8),

            // Habits List
            ...habits.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Row(
                children: [
                  Text(h.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('${h.category} • ${h.target} days/wk', style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey)),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        xp = (xp + 15) % 100;
                        if (xp < 15) level++;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Icon(CupertinoIcons.check_mark, size: 16, color: Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
