import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/history/data/models/cook_history_entry.dart';

/// "만든 요리" 카드.
///
/// 결과 화면의 풀스크린 카드보다 컴팩트하게: 좌측 이모지/카테고리 컬러,
/// 우측 텍스트(이름, 만든 시간, 메타), 우상단 삭제 액션.
class CookHistoryTile extends StatelessWidget {
  const CookHistoryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final CookHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              _Thumbnail(category: entry.recipe.category),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Body(entry: entry)),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                onPressed: onDelete,
                tooltip: '삭제',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientFor(category),
        ),
        borderRadius: AppRadius.rMd,
      ),
      child: Center(
        child: Text(_emoji(category), style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  static List<Color> _gradientFor(String category) {
    switch (category) {
      case '국·수프':
      case '국':
      case '찌개':
        return const <Color>[Color(0xFFFFF1E6), Color(0xFFFFDDC2)];
      case '볶음':
        return const <Color>[Color(0xFFFFE9DF), Color(0xFFFFB897)];
      case '반찬':
        return const <Color>[Color(0xFFFFF8E1), Color(0xFFFFE082)];
      case '밥·면':
        return const <Color>[Color(0xFFFFF3D6), Color(0xFFFFD89B)];
      default:
        return const <Color>[Color(0xFFFFEEE5), Color(0xFFFFCBAE)];
    }
  }

  static String _emoji(String category) {
    switch (category) {
      case '국·수프':
      case '국':
      case '찌개':
        return '🍲';
      case '볶음':
        return '🍳';
      case '반찬':
        return '🥢';
      case '밥·면':
        return '🍚';
      default:
        return '🍽️';
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.entry});

  final CookHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          entry.recipe.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatRelative(entry.cookedAt),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// "방금 전", "23분 전", "어제", "3일 전", "2026.05.10"식 한국어 상대시간.
  static String _formatRelative(DateTime when) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(when);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${when.year}.${when.month.toString().padLeft(2, '0')}.${when.day.toString().padLeft(2, '0')}';
  }
}
