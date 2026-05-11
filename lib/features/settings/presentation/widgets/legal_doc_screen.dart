import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({
    super.key,
    required this.title,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String effectiveDate;
  final String? intro;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.huge,
            ),
            children: <Widget>[
              _EffectiveDateBadge(date: effectiveDate),
              if (intro != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  intro!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              for (int i = 0; i < sections.length; i++) ...<Widget>[
                _SectionView(section: sections[i]),
                if (i != sections.length - 1)
                  const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

class _EffectiveDateBadge extends StatelessWidget {
  const _EffectiveDateBadge({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Text(
          '시행일 $date',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < section.paragraphs.length; i++) ...<Widget>[
          Text(
            section.paragraphs[i],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.7,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          if (i != section.paragraphs.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
