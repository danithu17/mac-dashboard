import 'package:flutter/cupertino.dart';

class AwardItem {
  final String title;
  final String desc;
  final String icon;
  final bool isUnlocked;

  AwardItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isUnlocked,
  });
}

class AwardsDialog extends StatelessWidget {
  final List<AwardItem> awards;

  const AwardsDialog({super.key, required this.awards});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = awards.where((a) => a.isUnlocked).length;

    return CupertinoPopupSurface(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF141824),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🏅', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      'Activity Awards',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              '$unlockedCount of ${awards.length} Medals Unlocked',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: awards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final award = awards[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: award.isUnlocked ? const Color(0xFF1C2234) : const Color(0xFF0F121C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: award.isUnlocked ? const Color(0x33F59E0B) : const Color(0x1AFFFFFF),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(award.icon, style: TextStyle(fontSize: 28, color: award.isUnlocked ? null : CupertinoColors.systemGrey)),
                        const SizedBox(height: 4),
                        Text(
                          award.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: award.isUnlocked ? CupertinoColors.white : CupertinoColors.systemGrey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          award.desc,
                          style: const TextStyle(fontSize: 9, color: CupertinoColors.systemGrey),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
