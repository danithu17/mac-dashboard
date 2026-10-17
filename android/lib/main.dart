import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'models/habit.dart';
import 'services/sync_service.dart';
import 'widgets/activity_rings.dart';
import 'widgets/awards_dialog.dart';
import 'widgets/sync_settings_dialog.dart';
import 'widgets/standby_modal.dart';

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
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: CupertinoColors.white,
          ),
        ),
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
  // Multi-Account Active State
  String _activeUid = 'usr_default';
  String _activeName = 'Danithu';
  String _activeTrack = 'Software Engineering';
  String _activeAvatar = '👤';
  List<Map<String, dynamic>> _availableUsers = [];

  int xp = 30;
  int level = 1;
  String currentRank = 'Initiate';
  bool isSynced = false;
  String currentFilter = 'All';

  // Notes & Mood
  String selectedMood = 'bolt';
  final TextEditingController _noteController = TextEditingController();

  // Focus Timer
  int _timerSeconds = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;

  final List<Habit> habits = [
    Habit(id: 'hab_code', name: 'Software Architecture', category: 'Coding', target: 7, icon: 'code', color: '#3b82f6'),
    Habit(id: 'hab_read', name: 'Deep Reading & Notes', category: 'Reading', target: 5, icon: 'book', color: '#10b981'),
    Habit(id: 'hab_fit', name: 'Strength Workout', category: 'Fitness', target: 5, icon: 'fitness', color: '#f43f5e'),
    Habit(id: 'hab_mind', name: 'Mindfulness & Breathing', category: 'Mindfulness', target: 7, icon: 'mindfulness', color: '#a855f7'),
    Habit(id: 'hab_hyd', name: 'Optimal Hydration', category: 'Hydration', target: 7, icon: 'hydration', color: '#06b6d4'),
  ];

  final Map<String, bool> _todayLogs = {};

  @override
  void initState() {
    super.initState();
    _noteController.text = 'Deep work sprint complete. High impact system architecture in progress.';
    _loadAccountAndSync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountAndSync() async {
    final activeUid = await SyncService.getActiveUid();
    final users = await SyncService.fetchAllUsers();
    if (mounted) {
      setState(() {
        _activeUid = activeUid;
        _availableUsers = users;
        final matched = users.firstWhere(
          (u) => u['uid'] == activeUid,
          orElse: () => users.isNotEmpty
              ? users.first
              : {'uid': activeUid, 'name': 'Danithu', 'track': 'Software Engineering', 'avatar': '👤'},
        );
        _activeUid = matched['uid'] ?? activeUid;
        _activeName = matched['name'] ?? 'Danithu';
        _activeTrack = matched['track'] ?? 'Software Engineering';
        _activeAvatar = matched['avatar'] ?? '👤';
      });
    }
    await _trySync();
  }

  Future<void> _trySync() async {
    final data = await SyncService.fetchUserData(_activeUid);
    if (data != null && mounted) {
      setState(() {
        isSynced = true;
        if (data['boost'] != null && data['boost']['bonusXp'] != null) {
          xp = (data['boost']['bonusXp'] as num).toInt();
          level = (xp ~/ 100) + 1;
          _updateRank();
        }
        if (data['habits'] != null && (data['habits'] as List).isNotEmpty) {
          habits.clear();
          for (var item in data['habits']) {
            habits.add(Habit.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        if (data['logs'] != null && data['logs'][_todayKey()] != null) {
          _todayLogs.clear();
          final dayMap = Map<String, dynamic>.from(data['logs'][_todayKey()]);
          dayMap.forEach((k, v) {
            _todayLogs[k] = v == true;
          });
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
        _updateRank();
      }
    });

    // Auto-sync with server
    SyncService.pushUserData(
      _activeUid,
      {
        'boost': {'bonusXp': xp, 'level': level},
        'habits': habits.map((h) => h.toJson()).toList(),
        'logs': {_todayKey(): _todayLogs}
      },
      {'name': _activeName, 'uid': _activeUid, 'track': _activeTrack, 'avatar': _activeAvatar},
    );
  }

  void _showAccountSwitcherActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_2_fill, color: Color(0xFF60A5FA), size: 16),
            SizedBox(width: 6),
            Text('Apple Ecosystem Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        message: const Text('Switch profile across Web, Desktop, and Android in real-time.'),
        actions: [
          ..._availableUsers.map((u) {
            final isCurrent = u['uid'] == _activeUid;
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _switchAccount(u['uid']);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x333B82F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(u['avatar'] ?? '👤', style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? 'User',
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: CupertinoColors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            u['track'] ?? 'Personal',
                            style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isCurrent)
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: Color(0xFF10B981), size: 20),
                ],
              ),
            );
          }),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddAccountDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add_circled, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 8),
                Text('+ Add Apple Profile', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _switchAccount(String uid) async {
    await SyncService.setActiveUid(uid);
    await _loadAccountAndSync();
  }

  void _showAddAccountDialog() {
    final nameCtrl = TextEditingController();
    final trackCtrl = TextEditingController(text: 'Software Engineering');
    final pinCtrl = TextEditingController(text: '1234');

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Apple Profile'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              CupertinoTextField(
                controller: nameCtrl,
                placeholder: 'Profile Name (e.g. Danithu)',
                style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: trackCtrl,
                placeholder: 'Workspace Track (e.g. iOS Development)',
                style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: pinCtrl,
                placeholder: '4-Digit PIN',
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: CupertinoColors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Create & Sync'),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newUid = 'usr_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
              await SyncService.createOrUpdateUser({
                'uid': newUid,
                'name': name,
                'track': trackCtrl.text.trim(),
                'avatar': '👤',
                'pin': pinCtrl.text.trim(),
              });
              await SyncService.setActiveUid(newUid);
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadAccountAndSync();
            },
          ),
        ],
      ),
    );
  }

  void _openStandbyMode() {
    final checkedCount = _todayLogs.values.where((v) => v).length;
    final habitsPct = habits.isEmpty ? 0.0 : (checkedCount / habits.length);
    final focusPct = (xp / 100.0).clamp(0.0, 1.0);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => AppleStandbyModal(
          userName: _activeName,
          habitsPct: habitsPct,
          focusPct: focusPct,
        ),
      ),
    );
  }

  void _updateRank() {
    if (level >= 8) {
      currentRank = 'Grandmaster';
    } else if (level >= 5) {
      currentRank = 'Vanguard';
    } else if (level >= 3) {
      currentRank = 'Architect';
    } else if (level >= 2) {
      currentRank = 'Practitioner';
    } else {
      currentRank = 'Initiate';
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
            _updateRank();
          });
          SyncService.pushUserData(
            _activeUid,
            {
              'boost': {'bonusXp': xp, 'level': level},
              'habits': habits.map((h) => h.toJson()).toList(),
              'logs': {_todayKey(): _todayLogs}
            },
            {'name': _activeName, 'uid': _activeUid, 'track': _activeTrack, 'avatar': _activeAvatar},
          );
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text(' Focus Completed!'),
              content: const Text('+25 Profile Boost XP Earned and synchronized with your Apple Ecosystem.'),
              actions: [
                CupertinoDialogAction(child: const Text('Great'), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          );
        }
      });
    }
  }

  IconData _getCupertinoIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'code':
      case 'coding':
      case '💻':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'book':
      case 'reading':
      case '📚':
      case '📖':
        return CupertinoIcons.book_fill;
      case 'fitness':
      case 'workout':
      case 'run':
      case '🏋️':
      case '🏃':
        return CupertinoIcons.flame_fill;
      case 'mindfulness':
      case 'meditate':
      case '🧘':
        return CupertinoIcons.sparkles;
      case 'hydration':
      case 'water':
      case '💧':
        return CupertinoIcons.drop_fill;
      case 'bolt':
      case '⚡':
        return CupertinoIcons.bolt_fill;
      case 'target':
      case '🎯':
        return CupertinoIcons.scope;
      default:
        return CupertinoIcons.star_fill;
    }
  }

  void _openAwards() {
    final checkedCount = _todayLogs.values.where((v) => v).length;
    final awards = [
      AwardItem(
        title: 'First Step',
        desc: 'Completed your very first habit check-in.',
        icon: CupertinoIcons.star_fill,
        color: const Color(0xFFF59E0B),
        isUnlocked: checkedCount >= 1,
      ),
      AwardItem(
        title: '7-Day Streak',
        desc: 'Maintained 7 consecutive active check-in days.',
        icon: CupertinoIcons.flame_fill,
        color: const Color(0xFFEF4444),
        isUnlocked: xp >= 30,
      ),
      AwardItem(
        title: 'Deep Work Master',
        desc: 'Earned 50+ Focus XP in Pomodoro sessions.',
        icon: CupertinoIcons.bolt_fill,
        color: const Color(0xFF3B82F6),
        isUnlocked: xp >= 50,
      ),
      AwardItem(
        title: 'Perfect Day',
        desc: 'Achieved 100% check-ins on all active habits.',
        icon: CupertinoIcons.checkmark_seal_fill,
        color: const Color(0xFFEC4899),
        isUnlocked: checkedCount == habits.length && habits.isNotEmpty,
      ),
      AwardItem(
        title: 'Century Club',
        desc: 'Logged 100 lifetime habit check-ins.',
        icon: CupertinoIcons.shield_fill,
        color: const Color(0xFF06B6D4),
        isUnlocked: false,
      ),
      AwardItem(
        title: 'Knowledge Vanguard',
        desc: 'Logged 10 deep reading & architecture sessions.',
        icon: CupertinoIcons.book_fill,
        color: const Color(0xFF10B981),
        isUnlocked: true,
      ),
      AwardItem(
        title: 'Apex Vanguard',
        desc: 'Reached Profile Boost Level 5.',
        icon: CupertinoIcons.sparkles,
        color: const Color(0xFF8B5CF6),
        isUnlocked: level >= 5,
      ),
      AwardItem(
        title: 'Monthly Legend',
        desc: 'Logged 20+ active days in consistency history.',
        icon: CupertinoIcons.rosette,
        color: const Color(0xFFEAB308),
        isUnlocked: true,
      ),
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
    final overallPct = habits.isEmpty ? 0.0 : (checkedCount / habits.length);
    final media = MediaQuery.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(CupertinoIcons.circle_grid_hex_fill, size: 14, color: CupertinoColors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'PulseHabit Pro',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openAwards,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0x26F59E0B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.rosette, color: Color(0xFFF59E0B), size: 16),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openSyncSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSynced ? const Color(0x3310B981) : const Color(0x33F59E0B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSynced ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.arrow_2_circlepath,
                      size: 11,
                      color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSynced ? 'Live Sync' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + media.padding.bottom,
          ),
          children: [
            // 1. PROFILE BOOST BANNER (Apple Glass Card - Tap to Switch Profiles)
            GestureDetector(
              onTap: _showAccountSwitcherActionSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x2E3B82F6)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x333B82F6), blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(_activeAvatar, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(_activeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0x333B82F6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0x403B82F6), width: 0.8),
                                    ),
                                    child: Text(currentRank, style: const TextStyle(fontSize: 9, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.chevron_down, size: 10, color: Color(0xFF60A5FA)),
                                ],
                              ),
                              Text('$_activeTrack • Tap to Switch', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.sparkles, size: 12, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text('Level $level', style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text('$xp / 100 XP', style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
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
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Row(
                children: [
                  ActivityRingsWidget(
                    overallPct: overallPct,
                    craftPct: 0.70,
                    vitalityPct: 0.50,
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
                        _RingLegend(color: const Color(0xFFFA114F), label: 'Daily Habits: ${(overallPct * 100).round()}%'),
                        const SizedBox(height: 4),
                        const _RingLegend(color: Color(0xFFA4FF00), label: 'Focus & Craft: 70%'),
                        const SizedBox(height: 4),
                        const _RingLegend(color: Color(0xFF00F5EA), label: 'Vitality & Mind: 50%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. CATEGORY PILLS (Horizontal Scroll with SF Symbols)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _categoryChip('All', CupertinoIcons.square_grid_2x2),
                  _categoryChip('Coding', CupertinoIcons.chevron_left_slash_chevron_right),
                  _categoryChip('Reading', CupertinoIcons.book),
                  _categoryChip('Fitness', CupertinoIcons.flame),
                  _categoryChip('Mindfulness', CupertinoIcons.sparkles),
                  _categoryChip('Hydration', CupertinoIcons.drop),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. HABITS CHECKLIST
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DAILY HABITS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey, letterSpacing: 0.6),
                ),
                Text(
                  '$checkedCount / ${habits.length} Done',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...filteredHabits.map((h) {
              final isDone = _todayLogs[h.id] ?? false;
              final colorVal = int.parse(h.color.replaceFirst('#', '0xFF'));
              final itemColor = Color(colorVal);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDone ? const Color(0x3310B981) : const Color(0x14FFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: itemColor.withOpacity(0.35), width: 0.8),
                      ),
                      child: Icon(
                        _getCupertinoIcon(h.icon),
                        size: 18,
                        color: itemColor,
                      ),
                    ),
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
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0x263B82F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.stopwatch_fill, color: Color(0xFF60A5FA), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('Focus Timer (+25 XP)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.white)),
                        ],
                      ),
                      Text(
                        '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF60A5FA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: _isTimerRunning ? CupertinoColors.systemYellow : CupertinoColors.systemBlue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: _toggleTimer,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isTimerRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 14, color: _isTimerRunning ? CupertinoColors.black : CupertinoColors.white),
                              const SizedBox(width: 6),
                              Text(
                                _isTimerRunning ? 'Pause' : 'Start Focus',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isTimerRunning ? CupertinoColors.black : CupertinoColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        color: const Color(0x33A855F7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _openStandbyMode,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.sparkles, size: 13, color: Color(0xFFC084FC)),
                            SizedBox(width: 4),
                            Text('Standby', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC084FC))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        color: const Color(0xFF1E2336),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0x26F59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.square_pencil, color: Color(0xFFFBBF24), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('Quick Notes & Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: CupertinoColors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 4),
                          Text(_todayKey(), style: const TextStyle(fontSize: 10, color: CupertinoColors.systemGrey, fontFamily: 'monospace')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _noteController,
                    maxLines: 3,
                    placeholder: 'Log daily focus, thoughts or reflections...',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F30),
                      borderRadius: BorderRadius.circular(14),
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

  Widget _categoryChip(String cat, IconData icon) {
    final isSelected = currentFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        color: isSelected ? CupertinoColors.systemBlue : const Color(0xFF181D2D),
        borderRadius: BorderRadius.circular(14),
        minSize: 28,
        onPressed: () => setState(() => currentFilter = cat),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey),
            const SizedBox(width: 5),
            Text(
              cat,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? CupertinoColors.white : CupertinoColors.systemGrey,
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
