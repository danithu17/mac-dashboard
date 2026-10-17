import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'models/habit.dart';
import 'services/sync_service.dart';
import 'widgets/activity_rings.dart';
import 'widgets/awards_dialog.dart';
import 'widgets/sync_settings_dialog.dart';
import 'widgets/standby_modal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        primaryColor: Color(0xFF007AFF), // Apple System Blue
        primaryContrastingColor: CupertinoColors.white,
        scaffoldBackgroundColor: Color(0xFF000000), // OLED Pure Black
        barBackgroundColor: Color(0xD912141F), // Frosted Acrylic Glass
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: CupertinoColors.white,
            letterSpacing: -0.3,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            color: CupertinoColors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: '.SF Pro Text',
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
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

  // Boost, Rank & Sync Status
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
  String _selectedPreset = '25';
  String _activeSoundscape = 'none';

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
    HapticFeedback.lightImpact();
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

  String _getFormattedDateHeader() {
    final now = DateTime.now();
    const weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  void _setTimerPreset(int minutes) {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _selectedPreset = minutes.toString();
      _isTimerRunning = false;
      _timerSeconds = minutes * 60;
    });
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
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
          HapticFeedback.heavyImpact();
          setState(() {
            _isTimerRunning = false;
            xp += 25;
            _timerSeconds = int.parse(_selectedPreset) * 60;
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

  void _openStandbyMode() {
    HapticFeedback.mediumImpact();
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

  void _showAccountSwitcherActionSheet() {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_2_fill, color: Color(0xFF007AFF), size: 16),
            SizedBox(width: 6),
            Text('Apple Ecosystem Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        message: const Text('Select an active profile to sync seamlessly across Web, Desktop, and Android.'),
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
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0x33007AFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(u['avatar'] ?? '👤', style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
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
    HapticFeedback.selectionClick();
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

  void _openSyncSettings() {
    HapticFeedback.selectionClick();
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

  IconData _getCupertinoIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'code':
      case 'coding':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'book':
      case 'reading':
        return CupertinoIcons.book_fill;
      case 'fitness':
      case 'workout':
      case 'run':
        return CupertinoIcons.flame_fill;
      case 'mindfulness':
      case 'meditate':
        return CupertinoIcons.sparkles;
      case 'hydration':
      case 'water':
        return CupertinoIcons.drop_fill;
      case 'bolt':
        return CupertinoIcons.bolt_fill;
      default:
        return CupertinoIcons.star_fill;
    }
  }

  Color _getIconBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'coding':
        return const Color(0xFF007AFF);
      case 'reading':
        return const Color(0xFF34C759);
      case 'fitness':
        return const Color(0xFFFF2D55);
      case 'mindfulness':
        return const Color(0xFFAF52DE);
      case 'hydration':
        return const Color(0xFF5AC8FA);
      default:
        return const Color(0xFFFF9500);
    }
  }

  List<AwardItem> _getAwardsList() {
    final checkedCount = _todayLogs.values.where((v) => v).length;
    return [
      AwardItem(
        title: 'First Step',
        desc: 'Completed your first check-in.',
        icon: CupertinoIcons.star_fill,
        color: const Color(0xFFF59E0B),
        isUnlocked: checkedCount >= 1,
      ),
      AwardItem(
        title: '7-Day Streak',
        desc: 'Maintained consistency for 7 days.',
        icon: CupertinoIcons.flame_fill,
        color: const Color(0xFFEF4444),
        isUnlocked: true,
      ),
      AwardItem(
        title: 'Deep Work Champion',
        desc: 'Reached 90+ minutes of deep focus.',
        icon: CupertinoIcons.hourglass_bottomhalf_fill,
        color: const Color(0xFF3B82F6),
        isUnlocked: xp >= 60,
      ),
      AwardItem(
        title: 'Mindful Master',
        desc: 'Completed zen breathing sessions.',
        icon: CupertinoIcons.sparkles,
        color: const Color(0xFFA855F7),
        isUnlocked: true,
      ),
      AwardItem(
        title: 'Perfect Week',
        desc: 'Hit 100% of weekly target habits.',
        icon: CupertinoIcons.check_mark_seal_fill,
        color: const Color(0xFF10B981),
        isUnlocked: false,
      ),
      AwardItem(
        title: 'Century Club',
        desc: 'Earned 100+ lifetime XP points.',
        icon: CupertinoIcons.rosette,
        color: const Color(0xFFEC4899),
        isUnlocked: xp >= 100 || level > 1,
      ),
      AwardItem(
        title: 'Early Bird',
        desc: 'Checked in before 8:00 AM.',
        icon: CupertinoIcons.sunrise_fill,
        color: const Color(0xFFF97316),
        isUnlocked: true,
      ),
      AwardItem(
        title: 'Ecosystem Master',
        desc: 'Live synced on Web, Mac & Android.',
        icon: CupertinoIcons.device_laptop,
        color: const Color(0xFF06B6D4),
        isUnlocked: isSynced,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xF210121A),
        activeColor: const Color(0xFF007AFF),
        inactiveColor: const Color(0xFF8E8E93),
        iconSize: 22,
        border: const Border(
          top: BorderSide(color: Color(0x2EFFFFFF), width: 0.5),
        ),
        onTap: (index) {
          HapticFeedback.selectionClick();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.circle_grid_hex),
            activeIcon: Icon(CupertinoIcons.circle_grid_hex_fill),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.timer),
            activeIcon: Icon(CupertinoIcons.timer_fill),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_pencil),
            activeIcon: Icon(CupertinoIcons.square_pencil_fill),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.rosette),
            activeIcon: Icon(CupertinoIcons.rosette),
            label: 'Awards',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return _buildSummaryTab(context);
          case 1:
            return _buildFocusTab(context);
          case 2:
            return _buildReflectTab(context);
          case 3:
          default:
            return _buildAwardsTab(context);
        }
      },
    );
  }

  // =========================================================================
  // TAB 1: SUMMARY (ACTIVITY RINGS & HABITS)
  // =========================================================================
  Widget _buildSummaryTab(BuildContext context) {
    final filteredHabits = currentFilter == 'All'
        ? habits
        : habits.where((h) => h.category == currentFilter).toList();

    final checkedCount = _todayLogs.values.where((v) => v).length;
    final overallPct = habits.isEmpty ? 0.0 : (checkedCount / habits.length);
    final focusPct = (xp / 100.0).clamp(0.0, 1.0);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Summary'),
            previousPageTitle: '',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openSyncSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSynced ? const Color(0x3310B981) : const Color(0x33F59E0B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        width: 0.8,
                      ),
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
                          isSynced ? 'Synced' : 'Offline',
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
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showAccountSwitcherActionSheet,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E2232),
                      border: Border.all(color: const Color(0xFF007AFF), width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(_activeAvatar, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Date Subtitle
                Text(
                  _getFormattedDateHeader(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // 1. APPLE ID PROFILE CARD
                GestureDetector(
                  onTap: _showAccountSwitcherActionSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33007AFF), blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(_activeAvatar, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _activeName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0x33007AFF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0x4D007AFF), width: 0.8),
                                    ),
                                    child: Text(
                                      currentRank,
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$_activeTrack • Apple ID Sync',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('Level $level', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24))),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        height: 5,
                                        color: const Color(0xFF2C2C2E),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: (xp / 100.0).clamp(0.05, 1.0),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$xp/100 XP', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF8E8E93))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. CONCENTRIC ACTIVITY RINGS CARD (Apple Fitness Style)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      ActivityRingsWidget(
                        overallPct: overallPct,
                        craftPct: focusPct,
                        vitalityPct: 0.85,
                        size: 130,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activity Rings',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            const SizedBox(height: 8),
                            _buildRingStatItem(
                              color: const Color(0xFFFA114F),
                              title: 'Move',
                              value: '$checkedCount / ${habits.length} Habits',
                              pct: '${(overallPct * 100).round()}%',
                            ),
                            const SizedBox(height: 6),
                            _buildRingStatItem(
                              color: const Color(0xFFA4FF00),
                              title: 'Exercise',
                              value: '$xp / 100 Focus XP',
                              pct: '${(focusPct * 100).round()}%',
                            ),
                            const SizedBox(height: 6),
                            _buildRingStatItem(
                              color: const Color(0xFF00F5EA),
                              title: 'Vitality',
                              value: '7-Day Streak',
                              pct: '85%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. TODAY'S HABITS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TODAY\'S HABITS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$checkedCount of ${habits.length} Complete',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Apple Sliding Segmented Control for Categories
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<String>(
                    backgroundColor: const Color(0xFF1C1C1E),
                    thumbColor: const Color(0xFF3A3A3C),
                    groupValue: currentFilter,
                    children: const {
                      'All': Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('All', style: TextStyle(fontSize: 12))),
                      'Coding': Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('Coding', style: TextStyle(fontSize: 12))),
                      'Reading': Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('Reading', style: TextStyle(fontSize: 12))),
                      'Fitness': Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('Fitness', style: TextStyle(fontSize: 12))),
                      'Mindfulness': Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Text('Mind', style: TextStyle(fontSize: 12))),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        HapticFeedback.selectionClick();
                        setState(() => currentFilter = val);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Inset Grouped Habits Card (iOS Reminders / Settings Style)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                    ),
                    child: Column(
                      children: List.generate(filteredHabits.length, (idx) {
                        final h = filteredHabits[idx];
                        final isDone = _todayLogs[h.id] ?? false;
                        final isLast = idx == filteredHabits.length - 1;

                        return Container(
                          decoration: BoxDecoration(
                            border: isLast ? null : const Border(
                              bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.6),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Squircle Icon
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _getIconBgColor(h.category),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _getCupertinoIcon(h.icon),
                                  size: 18,
                                  color: CupertinoColors.white,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Habit Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDone ? const Color(0xFF8E8E93) : CupertinoColors.white,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    Text(
                                      '${h.category} • Target ${h.target} days/wk',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                                    ),
                                  ],
                                ),
                              ),

                              // Apple Circular Check Button
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _toggleCheckIn(h.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone ? const Color(0xFF34C759) : const Color(0x1AFFFFFF),
                                    border: Border.all(
                                      color: isDone ? const Color(0xFF34C759) : const Color(0x40FFFFFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(CupertinoIcons.check_mark, size: 16, color: CupertinoColors.white)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingStatItem({required Color color, required String title, required String value, required String pct}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: CupertinoColors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        Text(
          pct,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontFamily: 'monospace'),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: FOCUS & ZEN (STANDBY, POMODORO & SOUNDSCAPES)
  // =========================================================================
  Widget _buildFocusTab(BuildContext context) {
    final mStr = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final sStr = (_timerSeconds % 60).toString().padLeft(2, '0');

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Focus & Zen'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openStandbyMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x33A855F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA855F7), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.sparkles, size: 12, color: Color(0xFFC084FC)),
                    SizedBox(width: 4),
                    Text('Standby', style: TextStyle(fontSize: 11, color: Color(0xFFC084FC), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. FOCUS TIMER HERO CARD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0x33007AFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(CupertinoIcons.timer, color: Color(0xFF007AFF), size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text('Pomodoro Sprint', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x26FBBF24),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('+25 XP / Session', style: TextStyle(fontSize: 10, color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Giant SF Timer Display
                      Text(
                        '$mStr:$sStr',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          letterSpacing: -1.5,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const Text(
                        'Deep Focus Interval',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 20),

                      // Preset Segmented Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPresetBtn('25 min', 25),
                          const SizedBox(width: 8),
                          _buildPresetBtn('50 min', 50),
                          const SizedBox(width: 8),
                          _buildPresetBtn('5 min', 5),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Timer Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: _isTimerRunning ? const Color(0xFFFF9500) : const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(14),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onPressed: _toggleTimer,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isTimerRunning ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 16, color: CupertinoColors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isTimerRunning ? 'Pause Focus' : 'Start Focus',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: CupertinoColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CupertinoButton(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(14),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _timer?.cancel();
                              setState(() {
                                _isTimerRunning = false;
                                _timerSeconds = int.parse(_selectedPreset) * 60;
                              });
                            },
                            child: const Text('Reset', style: TextStyle(color: CupertinoColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. SPATIAL FOCUS SOUNDSCAPES CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(CupertinoIcons.headphones, size: 16, color: Color(0xFF007AFF)),
                              SizedBox(width: 8),
                              Text(
                                'Ambient Soundscapes',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                              ),
                            ],
                          ),
                          if (_activeSoundscape != 'none')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x3310B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Active', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Calming background noise to keep you locked in focus.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          _buildSoundscapeBtn('rain', '🌧️ Rain'),
                          const SizedBox(width: 8),
                          _buildSoundscapeBtn('waves', '🌊 Waves'),
                          const SizedBox(width: 8),
                          _buildSoundscapeBtn('forest', '🌲 Forest'),
                          const SizedBox(width: 8),
                          _buildSoundscapeBtn('none', 'Mute'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. APPLE STANDBY AMBIENT MODE HERO BANNER
                GestureDetector(
                  onTap: _openStandbyMode,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E1065), Color(0xFF0F0728)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x4DA855F7), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x33A855F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66A855F7)),
                          ),
                          child: const Icon(CupertinoIcons.sparkles, color: Color(0xFFC084FC), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ' Standby Zen Mode',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                              ),
                              Text(
                                'Full-screen glowing clock & Activity rings',
                                style: TextStyle(fontSize: 12, color: Color(0xFFD8B4FE)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFFD8B4FE)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, int mins) {
    final isSelected = _selectedPreset == mins.toString();
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
        onPressed: () => _setTimerPreset(mins),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundscapeBtn(String key, String label) {
    final isSelected = _activeSoundscape == key;
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: isSelected ? const Color(0x33007AFF) : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _activeSoundscape = key);
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF38BDF8) : CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: REFLECT (APPLE NOTES & MOOD)
  // =========================================================================
  Widget _buildReflectTab(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Reflect'),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. MOOD & ENERGY SELECTOR
                const Text(
                  'CURRENT ENERGY & MOOD',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildMoodChip('bolt', '⚡ High'),
                    const SizedBox(width: 6),
                    _buildMoodChip('rocket', '🚀 Flow'),
                    const SizedBox(width: 6),
                    _buildMoodChip('peace', '😌 Calm'),
                    const SizedBox(width: 6),
                    _buildMoodChip('brain', '🧠 Focus'),
                    const SizedBox(width: 6),
                    _buildMoodChip('battery', '🔋 Rest'),
                  ],
                ),

                const SizedBox(height: 20),

                // 2. APPLE NOTES DAILY REFLECTION CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
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
                                  color: const Color(0x33F59E0B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(CupertinoIcons.doc_text_fill, color: Color(0xFFF59E0B), size: 16),
                              ),
                              const SizedBox(width: 10),
                              const Text('Daily Reflection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Text('Today', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      CupertinoTextField(
                        controller: _noteController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 13, color: CupertinoColors.white, height: 1.4),
                        placeholder: 'Write your thoughts, key learnings, or reflections for today...',
                        placeholderStyle: const TextStyle(color: Color(0xFF636366), fontSize: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12141F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(CupertinoIcons.cloud_upload, size: 12, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text('Auto-saved to Cloud', style: TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                            ],
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              SyncService.pushUserData(
                                _activeUid,
                                {
                                  'boost': {'bonusXp': xp, 'level': level},
                                  'habits': habits.map((h) => h.toJson()).toList(),
                                  'logs': {_todayKey(): _todayLogs},
                                  'dailyNotes': {_todayKey(): {'text': _noteController.text.trim()}}
                                },
                                {'name': _activeName, 'uid': _activeUid, 'track': _activeTrack, 'avatar': _activeAvatar},
                              );
                            },
                            child: const Text('Save Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. CONSISTENCY MATRIX HEATMAP
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(CupertinoIcons.calendar, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text('Consistency Heatmap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text('35 Days', style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 5x7 Grid Squares
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: 35,
                        itemBuilder: (context, index) {
                          final isToday = index == 34;
                          final isActive = index % 3 != 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF10B981)
                                  : (isActive ? const Color(0x6610B981) : const Color(0x1AFFFFFF)),
                              borderRadius: BorderRadius.circular(4),
                              border: isToday ? Border.all(color: CupertinoColors.white, width: 1) : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🔥 7-Day Active Streak', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          Text('Less ■ ■ ■ ■ More', style: TextStyle(fontSize: 10, color: Color(0xFF8E8E93))),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String key, String label) {
    final isSelected = selectedMood == key;
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: isSelected ? const Color(0x33007AFF) : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => selectedMood = key);
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF38BDF8) : CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 4: AWARDS & ECOSYSTEM CLOUD
  // =========================================================================
  Widget _buildAwardsTab(BuildContext context) {
    final awards = _getAwardsList();

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Awards & Cloud'),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. APPLE ID BANNER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x33007AFF),
                          border: Border.all(color: const Color(0xFF007AFF)),
                        ),
                        alignment: Alignment.center,
                        child: Text(_activeAvatar, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_activeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                            Text(_activeTrack, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: const Color(0x33007AFF),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _showAccountSwitcherActionSheet,
                        child: const Text('Switch', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. APPLE WATCH MEDALS GALLERY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'APPLE WATCH MEDALS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93), letterSpacing: 0.5),
                    ),
                    Text(
                      '${awards.where((a) => a.isUnlocked).length} of ${awards.length} Unlocked',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: awards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (ctx, i) {
                    final award = awards[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: award.isUnlocked ? const Color(0xFF1C1C1E) : const Color(0xFF12141F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: award.isUnlocked ? award.color.withOpacity(0.4) : const Color(0x14FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: award.isUnlocked
                                  ? LinearGradient(
                                      colors: [award.color.withOpacity(0.9), award.color.withOpacity(0.5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: award.isUnlocked ? null : const Color(0x1AFFFFFF),
                            ),
                            child: Icon(
                              award.icon,
                              size: 18,
                              color: award.isUnlocked ? CupertinoColors.white : CupertinoColors.systemGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            award.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: award.isUnlocked ? CupertinoColors.white : CupertinoColors.systemGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            award.desc,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93)),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 3. ZERO-COST CLOUD SYNC CONFIGURATION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x2EFFFFFF), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.cloud_fill, size: 16, color: Color(0xFF007AFF)),
                          SizedBox(width: 8),
                          Text('Ecosystem Cloud Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connected to zero-cost Vercel & local server endpoint for live multi-device syncing.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 12),

                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _openSyncSettings,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.slider_horizontal_3, size: 14, color: CupertinoColors.white),
                            SizedBox(width: 6),
                            Text('Configure Sync Server', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
