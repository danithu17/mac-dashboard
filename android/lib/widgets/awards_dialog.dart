import 'package:flutter/cupertino.dart';

class AwardItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  AwardItem({
    required this.title,
    required this.desc,
    required this.icon,
    this.color = const Color(0xFFF59E0B),
    required this.isUnlocked,
  });
}

class AwardsDialog extends StatelessWidget {
  final List<AwardItem> awards;

  const AwardsDialog({super.key, required this.awards});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = awards.where((a) => a.isUnlocked).length;
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 380;

    return CupertinoPopupSurface(
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        color: const Color(0xFF141824),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33F59E0B), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ],
                      child: const Icon(CupertinoIcons.rosette, color: CupertinoColors.black, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Activity Awards',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$unlockedCount of ${awards.length} Medals Unlocked',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: awards.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isCompact ? 1 : 2,
                  childAspectRatio: isCompact ? 2.4 : 1.15,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final award = awards[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: award.isUnlocked ? const Color(0xFF1A2030) : const Color(0xFF0F121C),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: award.isUnlocked ? award.color.withOpacity(0.35) : const Color(0x14FFFFFF),
                        width: 1,
                      ),
                      boxShadow: award.isUnlocked
                          ? [BoxShadow(color: award.color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))]
                          : null,
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
                            border: Border.all(
                              color: award.isUnlocked ? const Color(0x80FFFFFF) : const Color(0x22FFFFFF),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            award.icon,
                            size: 19,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          award.desc,
                          style: const TextStyle(fontSize: 9.5, color: CupertinoColors.systemGrey, height: 1.2),
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
